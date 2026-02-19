# Airis 发布清单（Release Checklist）

本项目通过 **GitHub Releases + Homebrew Cask（自建 tap）** 分发：

- GitHub Release 资产名：`Airis-<version>.zip`
- zip 内包含：`Airis-Dist.app/`
- Homebrew cask：`Wangnov/homebrew-tap` 的 `Casks/airis.rb` 指向上述 Release 资产

> 目标：每次发布都可重复、可核对、可回滚。

---

## 0. 前置条件（必须满足）

1) **GitHub**
- 已登录 `gh auth status`
- 对 `Wangnov/Airis`、`Wangnov/homebrew-tap` 有写权限

2) **macOS / Xcode**
- 本机可运行 `xcodebuild`（建议固定一个已验证的 Xcode 版本）
- Release 构建需要产出 **universal binary（arm64 + x86_64）**

3) **签名（Developer ID Application）**
- Keychain 中已安装可用的 `Developer ID Application` 证书
- 可用命令确认：
  - `security find-identity -v -p codesigning`

4) **公证（notarytool）**
- 已准备好 notarytool 凭据（推荐 `--keychain-profile <profile>`）
- 可用命令确认（需要你填 profile）：
  - `xcrun notarytool history --keychain-profile <profile>`

---

## 1. 版本号更新（例：1.0.1 -> 1.0.2）

### 1.1 必改位置

- CLI 版本输出（ArgumentParser）：
  - `Sources/AirisCore/Commands/Root.swift` 里的 `version: "x.y.z"`
- App 版本（用于 `.app` 包）：
  - `Sources/Airis/Info.plist`：`CFBundleShortVersionString` / `CFBundleVersion`
  - `project.yml`：同名字段（XcodeGen 生成用）
- 测试断言（防止漏改）：
  - `Tests/AirisTests/AirisTests.swift`
  - `Tests/AirisTests/CommandTests/RootCommandTests.swift`

### 1.2 快速自检

```bash
OLD=1.0.1
rg -n "\\b${OLD//./\\.}\\b" -S .
```

---

## 2. 测试（发布前必做）

```bash
make test-quick
```

如有高风险改动，建议：

```bash
make test
```

---

## 3. 构建 Release App（universal）

建议使用 Xcode 工程构建（保证 app wrapper / Info.plist / icon 等一致）。

```bash
DERIVED_DATA=dist/build
rm -rf "$DERIVED_DATA"

xcodebuild \
  -project Airis.xcodeproj \
  -scheme Airis \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS="arm64 x86_64" \
  build
```

构建产物一般在：

```bash
APP_SRC="$DERIVED_DATA/Build/Products/Release/Airis.app"
ls -la "$APP_SRC"
```

---

## 4. 生成分发包（签名 + 公证 + stapling）

Homebrew Cask 期望 zip 内为：`Airis-Dist.app/`。

### 4.1 准备分发目录

```bash
VERSION=1.0.2
DIST_DIR=dist
APP_DIST="$DIST_DIR/Airis-Dist.app"

rm -rf "$APP_DIST"
cp -R "$APP_SRC" "$APP_DIST"
```

### 4.2 重新签名（Developer ID Application）

分发版尽量使用空 entitlements（避免分发不可用能力）：

- `Airis-Distribution.entitlements`（空 dict）

```bash
IDENTITY="Developer ID Application: <YOUR_NAME> (<TEAM_ID>)"

codesign --force --deep --sign "$IDENTITY" \
  --options runtime --timestamp \
  --entitlements Airis-Distribution.entitlements \
  "$APP_DIST"
```

验证签名信息：

```bash
codesign -dv --verbose=4 "$APP_DIST" 2>&1 | sed -n '1,80p'
```

### 4.3 打包提交公证（用于 notarytool submit）

> 建议用 `ditto` 打包，尽量保留资源与签名元数据。

```bash
ZIP_SUBMIT="$DIST_DIR/Airis-$VERSION-submit.zip"
rm -f "$ZIP_SUBMIT"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIST" "$ZIP_SUBMIT"
```

### 4.4 公证 + stapling

```bash
NOTARY_PROFILE="<your-keychain-profile>"

xcrun notarytool submit "$ZIP_SUBMIT" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$APP_DIST"
```

验证 Gatekeeper：

```bash
spctl -a -vvv -t install "$APP_DIST"
```

### 4.5 生成最终发布 zip（用于 GitHub Release / Homebrew）

```bash
ZIP_FINAL="$DIST_DIR/Airis-$VERSION.zip"
rm -f "$ZIP_FINAL"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIST" "$ZIP_FINAL"

shasum -a 256 "$ZIP_FINAL"
```

---

## 5. GitHub tag + Release

### 5.1 打 tag 并推送

```bash
git tag "v$VERSION"
git push origin "v$VERSION"
```

### 5.2 创建 Release 并上传资产

```bash
gh release create "v$VERSION" "$ZIP_FINAL" \
  --title "Airis v$VERSION" \
  --notes "Patch release v$VERSION"
```

发布后自检：
- Release 页面是否包含 `Airis-$VERSION.zip`
- 下载并解压后是否存在 `Airis-Dist.app/`

---

## 6. 更新 Homebrew（tap）

Homebrew 仓库：`Wangnov/homebrew-tap`

1) 更新 `Casks/airis.rb`：
- `version "$VERSION"`
- `sha256 "<上一步 shasum 输出>"`

2) 验证安装（本机）：

```bash
brew tap wangnov/tap
brew install --cask airis
airis --version
```

---

## 7. 常见问题

### 7.1 notarytool 凭据缺失

需要先执行（仅示例，按你的账号策略配置）：

```bash
xcrun notarytool store-credentials "<profile>" \
  --apple-id "<APPLE_ID>" \
  --team-id "<TEAM_ID>" \
  --password "<APP_SPECIFIC_PASSWORD>"
```

### 7.2 Homebrew 分发不支持 `analyze safe`

这是 Apple provisioning 限制导致（Developer ID 分发不具备对应 entitlement 能力）。
如需该能力，请用 Xcode Development 构建。

