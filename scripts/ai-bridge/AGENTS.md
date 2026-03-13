# ai-bridge Coding Conventions

## Table Driven Tests

テスト関数は Table Driven Test 形式で実装する。テストケースを構造体スライスで定義し、
`name` フィールドでケースを識別する。テストロジックは一度だけ書き、各ケースの
input・output・error が一目でわかるようにする。

参考: <https://go.dev/wiki/TableDrivenTests>

**Good:**

```go
func TestParseRequest(t *testing.T) {
    t.Parallel()
    tests := []struct {
        name          string
        content       string  // input
        wantPrompt    string  // expected output
        wantErr       bool    // expected error
    }{
        {
            name:       "valid request returns parsed fields",
            content:    `{"prompt":"hello","cwd":"/tmp"}`,
            wantPrompt: "hello",
        },
        {
            name:    "missing prompt returns error",
            content: `{"cwd":"/tmp"}`,
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            // ...
        })
    }
}
```

### 構造体フィールドの命名規則

| 役割                     | フィールド名の例                         |
| ------------------------ | ---------------------------------------- |
| テストケース名           | `name`                                   |
| 関数への入力             | `input`, `cli`, `prompt`, `content` など |
| 期待する出力             | `want`, `wantPrompt`, `wantCWD` など     |
| エラーの有無             | `wantErr bool`                           |
| 期待するエラーメッセージ | `wantErrMsg string`                      |

### 例外: 検証ロジックが大きく異なるケース

同じ検証ロジックが共有できない場合（タイミング依存の統合テストなど）は、
無理に1つのテーブルにまとめず独立したテスト関数として書いてよい。

## テストの並列化

すべてのテスト関数とそのサブテストに `t.Parallel()` を付けて並列実行する。

**Good:**

```go
func TestFoo(t *testing.T) {
    t.Parallel()
    tests := []struct{ ... }{ ... }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            // ...
        })
    }
}
```

### 例外: `t.Setenv` を使うテスト

`t.Setenv` はパラレルテストで使用できない。Go 1.22 以降、親テストが
`t.Parallel()` を持つ場合でもサブテストで `t.Setenv` を呼ぶと panic になる。

`t.Setenv` を含むテスト関数は外側・サブテストともに `t.Parallel()` を付けない。

````go
// NOTE: t.Parallel() を付けない。
// Go 1.22 以降、親テストが Parallel の場合でもサブテストで t.Setenv が使えなくなる。
func TestLoadConfig(t *testing.T) {
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Setenv("KEY", tt.value) // parallel 不可
            // ...
        })
    }
}

## Error Variable Naming

同一関数スコープ内で複数のエラー変数を宣言する場合、すべてに操作を表す固有の名前を付ける。`err` の再利用・上書きは禁止。

**Bad:**

```go
data, err := os.ReadFile(path)
if err != nil { ... }

result, err := json.Unmarshal(data, &v) // err を上書き
if err != nil { ... }
````

**Good:**

```go
data, readErr := os.ReadFile(path)
if readErr != nil { ... }

unmarshalErr := json.Unmarshal(data, &v)
if unmarshalErr != nil { ... }
```

### 命名ガイドライン

`<動詞><対象>Err` の形式を基本とする。

| 操作                     | 変数名例         |
| ------------------------ | ---------------- |
| `os.UserHomeDir()`       | `homeDirErr`     |
| `os.MkdirAll(...)`       | `mkdirErr`       |
| `os.ReadFile(...)`       | `readErr`        |
| `os.WriteFile(...)`      | `writeErr`       |
| `os.CreateTemp(...)`     | `createTempErr`  |
| `os.Rename(...)`         | `renameErr`      |
| `os.Stat(...)`           | `statErr`        |
| `f.Chmod(...)`           | `chmodErr`       |
| `json.Unmarshal(...)`    | `unmarshalErr`   |
| `template.Parse(...)`    | `parseErr`       |
| `tmpl.Execute(...)`      | `executeErr`     |
| `launcher.New(...)`      | `newLauncherErr` |
| `daemon.LoadConfig()`    | `loadConfigErr`  |
| `GenerateScript(...)`    | `genScriptErr`   |
| `GeneratePlist(...)`     | `genPlistErr`    |
| `launchctl("load", ...)` | `loadErr`        |
| `l.Launch(...)`          | `launchErr`      |

### `if` スコープも同様に扱う

`if initStmt; condition` の形式も同一関数内の他のエラー変数名と重複させない。

**Bad:**

```go
data, err := os.ReadFile(path) // 関数スコープの err
if err != nil { ... }

if err := f.Chmod(0o755); err != nil { // if スコープで err を再宣言（シャドウイング）
    ...
}
```

**Good:**

```go
data, readErr := os.ReadFile(path)
if readErr != nil { ... }

if chmodErr := f.Chmod(0o755); chmodErr != nil {
    ...
}
```

## パッケージスコープの制限

パッケージ内でのみ呼ばれる関数・メソッドは unexported（小文字始まり）にする。

**Bad:**

```go
// Args は Launch() と同一パッケージのテストのみで使われているのに exported になっている
func (w *WezTerm) Args(cwd, scriptPath string) []string {
    return []string{"cli", "spawn", "--cwd", cwd, "--", "bash", "-l", scriptPath}
}
```

**Good:**

```go
func (w *WezTerm) args(cwd, scriptPath string) []string {
    return []string{"cli", "spawn", "--cwd", cwd, "--", "bash", "-l", scriptPath}
}
```

### 判断基準

関数・メソッドを exported にするのは、以下のいずれかを満たす場合のみ。

- 別パッケージから直接呼ばれる
- インターフェースの実装として外部に公開される必要がある

同一パッケージ内のコード（`_test.go` を含む）からしか呼ばれない場合は unexported にする。
