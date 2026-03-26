# Azure API Management ハンズオン

Azure API Management (APIM) の基本機能を体験するハンズオン資料です。  
2 種類の SKU（**Basic V2** と **Developer**）を実際にデプロイし、API の登録からポリシー適用までを段階的に学びます。

## 前提条件

- Azure サブスクリプション
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)（Azure CLI に同梱）

## プロジェクト構成

```
├── azure.yaml                  # azd プロジェクト定義
├── AGENTS.md                   # AI エージェント向けルール
├── infra/
│   ├── main.bicep              # メインテンプレート（APIM × 2）
│   ├── main.bicepparam         # パラメータファイル
│   ├── abbreviations.json      # リソース名の略称定義
│   └── modules/
│       └── api-management.bicep  # APIM モジュール（AVM 使用）
└── README.md
```

## デプロイされるリソース

| リソース | SKU | 用途 |
|---------|-----|------|
| API Management (Basic V2) | BasicV2 | v2 SKU の動作確認 |
| API Management (Developer) | Developer | v1 SKU の動作確認・比較 |

---

## Step 0: 環境のデプロイ

### 0-1. リポジトリのクローン

```bash
git clone https://github.com/h-morozumi/azure-apim-example.git
cd azure-apim-example
```

### 0-2. azd の初期化・パラメータ設定

```bash
azd init
azd env set AZURE_APIM_PUBLISHER_EMAIL "your-email@example.com"
azd env set AZURE_APIM_PUBLISHER_NAME "Your Organization"
```

### 0-3. デプロイ

```bash
azd up
```

> **注意**: APIM のプロビジョニングには **30〜50 分程度** かかります。

デプロイ完了後、以下の出力が表示されます：

```
APIM_BASICV2_NAME=apim-basicv2-xxxxx
APIM_BASICV2_GATEWAY_URL=https://apim-basicv2-xxxxx.azure-api.net
APIM_DEVELOPER_NAME=apim-dev-xxxxx
APIM_DEVELOPER_GATEWAY_URL=https://apim-dev-xxxxx.azure-api.net
```

---

## Step 1: Echo API で基本操作を学ぶ

Echo API は APIM にデフォルトで組み込まれている API です。セットアップ不要ですぐに使えます。

### 1-1. Azure ポータルで Echo API を確認

1. [Azure ポータル](https://portal.azure.com) を開く
2. デプロイされた API Management（Basic V2）を開く
3. 左メニュー **[API]** → **Echo API** を選択

### 1-2. テストコンソールで API を呼び出す

1. **Echo API** → **Retrieve resource** オペレーションを選択
2. **[Test]** タブをクリック
3. **[Send]** をクリック
4. レスポンスの **200 OK** と内容を確認

### 1-3. サブスクリプションキーの確認

1. 左メニュー **[サブスクリプション]** を開く
2. **Built-in all-access subscription** のキーを表示
3. ターミナルから curl で直接呼び出してみる：

```bash
# サブスクリプションキーを環境変数に設定
APIM_URL="<APIM_BASICV2_GATEWAY_URL>"
SUB_KEY="<your-subscription-key>"

# Echo API を呼び出し
curl -s "${APIM_URL}/echo/resource?param1=sample" \
  -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}" | jq .
```

### 1-4. サブスクリプションキーなしで呼び出す

```bash
# キーなしで呼び出すと 401 エラー
curl -s -o /dev/null -w "%{http_code}" "${APIM_URL}/echo/resource?param1=sample"
# → 401
```

---

## Step 2: JSONPlaceholder を外部 API として登録

[JSONPlaceholder](https://jsonplaceholder.typicode.com) は登録不要・認証不要のパブリック REST API です。

### 2-1. API を手動で登録

1. Azure ポータルで APIM（Basic V2）を開く
2. **[API]** → **[+ Add API]** → **HTTP** を選択
3. 以下を入力:

| 項目 | 値 |
|-----|-----|
| Display name | `JSONPlaceholder` |
| Name | `jsonplaceholder` |
| Web service URL | `https://jsonplaceholder.typicode.com` |
| API URL suffix | `jsonplaceholder` |

4. **[Create]** をクリック

### 2-2. オペレーションを追加

**Get Posts（一覧取得）**

| 項目 | 値 |
|-----|-----|
| Display name | `Get Posts` |
| URL | GET `/posts` |

**Get Post by ID（1件取得）**

| 項目 | 値 |
|-----|-----|
| Display name | `Get Post by ID` |
| URL | GET `/posts/{id}` |

Template parameters に `id`（type: integer）を追加。

**Create Post（作成）**

| 項目 | 値 |
|-----|-----|
| Display name | `Create Post` |
| URL | POST `/posts` |

### 2-3. テストコンソールで動作確認

```bash
# 投稿一覧の取得
curl -s "${APIM_URL}/jsonplaceholder/posts" \
  -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}" | jq '.[0:3]'

# 投稿1件の取得
curl -s "${APIM_URL}/jsonplaceholder/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}" | jq .

# 投稿の作成（疑似）
curl -s -X POST "${APIM_URL}/jsonplaceholder/posts" \
  -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Hello APIM","body":"This is a test","userId":1}' | jq .
```

---

## Step 3: ポリシーを適用する

### 3-1. レスポンスヘッダーの追加

JSONPlaceholder API の **All operations** を選択し、Outbound processing に以下のポリシーを追加：

```xml
<outbound>
    <base />
    <set-header name="X-Custom-Header" exists-action="override">
        <value>Hello from APIM</value>
    </set-header>
</outbound>
```

確認：

```bash
curl -si "${APIM_URL}/jsonplaceholder/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}" | grep -i x-custom
# → X-Custom-Header: Hello from APIM
```

### 3-2. レート制限（Rate Limiting）

Inbound processing に以下を追加（1分間に5回まで）：

```xml
<inbound>
    <base />
    <rate-limit calls="5" renewal-period="60" />
</inbound>
```

確認：

```bash
# 6回連続で呼び出すと、6回目で 429 Too Many Requests
for i in $(seq 1 6); do
  echo "Request $i: $(curl -s -o /dev/null -w '%{http_code}' \
    "${APIM_URL}/jsonplaceholder/posts/1" \
    -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}")"
done
```

### 3-3. レスポンスの変換（JSON → XML）

特定オペレーション（Get Post by ID）の Outbound に追加：

```xml
<outbound>
    <base />
    <json-to-xml apply="always" consider-accept-header="true" />
</outbound>
```

確認：

```bash
curl -s "${APIM_URL}/jsonplaceholder/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUB_KEY}" \
  -H "Accept: application/xml"
```

### 3-4. CORS の設定

All operations の Inbound に CORS ポリシーを追加：

```xml
<inbound>
    <base />
    <cors allow-credentials="false">
        <allowed-origins>
            <origin>*</origin>
        </allowed-origins>
        <allowed-methods>
            <method>GET</method>
            <method>POST</method>
        </allowed-methods>
        <allowed-headers>
            <header>*</header>
        </allowed-headers>
    </cors>
</inbound>
```

---

## Step 4: Developer Portal を体験する

### 4-1. Developer Portal を有効化

1. Azure ポータルで APIM を開く
2. 左メニュー **[Developer portal]** → **[Portal overview]** を選択
3. **[Enable Developer Portal]** が有効であることを確認
4. **[Developer portal]** ボタンをクリックして管理画面を開く
5. **[Publish]** で公開する

### 4-2. Developer Portal にアクセス

```
https://<APIM名>.developer.azure-api.net
```

- API 一覧の確認
- API のテスト実行
- サブスクリプションキーの管理

---

## Step 5: Basic V2 と Developer SKU を比較する

同じ JSONPlaceholder API を Developer SKU 側にも登録し、以下を比較してみましょう：

| 比較項目 | Basic V2 | Developer |
|---------|----------|-----------|
| デプロイ時間 | 数分 | 30〜50分 |
| スケーリング | 自動（1〜10） | 固定（1） |
| SLA | 99.95% | なし |
| セルフホスト型ゲートウェイ | 非対応 | 対応 |
| 価格モデル | 従量課金的 | 固定 |
| 用途 | 開発〜本番 | 開発・テスト |

---

## クリーンアップ

ハンズオン終了後、リソースを削除します：

```bash
azd down
```

> **`azd down`** はリソースグループごと削除します。APIM は Soft Delete されるため、完全削除したい場合は Azure ポータルから Purge してください。

---

## 参考リンク

- [Azure API Management ドキュメント](https://learn.microsoft.com/azure/api-management/)
- [API Management の SKU と機能比較](https://learn.microsoft.com/azure/api-management/api-management-features)
- [API Management のポリシー リファレンス](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [JSONPlaceholder](https://jsonplaceholder.typicode.com/)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/)