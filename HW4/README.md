# CG Assignments - Lab 4

## 完成項目

| 項目 | 檔案 / 函式 | 狀態 |
|---|---|---|
| 前置：貼上 HW1～HW3 的程式 | `util`、`Matrix4`、`Camera`、`GameObject`、`HW4` | ✅ 完成 |
| 重心座標（透視校正） | `util::barycentric` | ✅ 完成 |
| Phong Shading | `PhongMaterial`、`PhongVertexShader`、`PhongFragmentShader` | ✅ 完成 |
| Flat Shading | `FlatMaterial`、`FlatVertexShader`、`FlatFragmentShader` | ✅ 完成 |
| Gouraud Shading | `GouraudMaterial`、`GouraudVertexShader`、`GouraudFragmentShader` | ✅ 完成 |
| **Bonus：貼圖著色器** | `TextureMaterial`、`TextureVertexShader`、`TextureFragmentShader` | ✅ 完成 |
| **Bonus：修正框架的 bug** | 見下方「發現與修正的問題」 | ✅ 完成 |
| （選做）相機控制 | `HW4::cameraControl` | ✅ 完成 |

## 執行截圖

同一個模型分別使用四種材質：

| Flat | Gouraud |
|---|---|
| ![flat](flat.png) | ![gouraud](gouraud.png) |

| Phong | Texture（Bonus） |
|---|---|
| ![phong](phong.png) | ![texture](texture.png) |

## 操作方式

- 左上角第一個按鈕：載入 `.obj` 模型
- 在 Hierarchy 點選模型後，Inspector 最下面的**材質按鈕**可以依序切換：
  Phong → Texture → Depth → Flat → Gouraud → Phong …
- 點選 Light 可以調整光的顏色和強度；點選模型可以調整模型顏色
- 相機控制：**A / D** 左右轉、**W / S** 上下轉、**Q / E** 拉近拉遠、在畫布上拖曳旋轉、滾輪縮放

## 實作方式

### 1. 重心座標與透視校正

**第一步：螢幕空間的重心座標**

點 P 在三角形 ABC 裡的重心座標 (α, β, γ)，就是 P 和三條邊組成的三個小三角形，各自佔整個三角形面積的比例：

```
α = 面積(PBC) / 面積(ABC)
β = 面積(PCA) / 面積(ABC)
γ = 1 - α - β
```

面積用 2D 外積計算（帶正負號），所以 P 在三角形外時，對應的權重會是負的。

**第二步：透視校正**

透視投影後，螢幕上「等距」的點在 3D 空間裡並不等距（遠的地方被壓縮）。如果直接用螢幕空間的 (α, β, γ) 內插法向量或 UV，貼圖和光照會歪掉。

正確做法是利用「`1/w` 在螢幕上是線性的」這個性質：

```
α' = (α / w_A) / (α/w_A + β/w_B + γ/w_C)
β'、γ' 同理
```

`w` 就是頂點在裁剪空間的 w（等於觀察空間的深度）。

**測試**：在 3D 三角形上隨機取點，投影到螢幕後，用 `barycentric` 算出的權重和這個點原本在 3D 中的權重完全一致（2000 次測試）。

### 2. Phong 光照模型

三種著色方式共用同一個光照公式，寫在 `phongLighting()`：

```
顏色 = 環境光 + 漫反射 + 鏡面反射

環境光   = Ka × albedo
漫反射   = Kd × max(N·L, 0) × 光的顏色 × 強度 × albedo
鏡面反射 = Ks × max(R·V, 0)^m × 光的顏色 × 強度
```

- **N**：表面法向量
- **L**：從表面指向光源
- **V**：從表面指向相機
- **R** = `2(N·L)N - L`：光線對法向量的反射方向
- **m**：光澤度，越大反光點越小越集中

背光面（`N·L < 0`）沒有漫反射和鏡面反射，只剩環境光。最後把顏色限制在 [0, 1]，避免光的強度調高時顏色溢位。

### 3. 三種著色方式的差別

| | **Flat** | **Gouraud** | **Phong** |
|---|---|---|---|
| 在哪裡算光照 | 每個**三角形**算一次 | 每個**頂點**算一次 | 每個**像素**算一次 |
| 用什麼法向量 | 三角形的面法向量 | 頂點法向量 | 內插後的法向量 |
| 內插什麼 | 不內插，整面同色 | 內插**顏色** | 內插**法向量和位置** |
| 外觀 | 看得到一塊一塊的面 | 平滑，但反光點會糊掉或閃爍 | 最平滑，反光點最準確 |
| 計算量 | 最少 | 中等 | 最多 |

- **Flat**：在 vertex shader 用兩條邊的外積算面法向量，在三角形中心算光照，三個頂點傳同樣的顏色，所以整個面是同一個顏色。外積的方向可能朝內，所以我讓它和頂點法向量的平均方向比較，方向相反就翻過來。
- **Gouraud**：在 vertex shader 用每個頂點的法向量算光照，把顏色當作 varying 傳出去，GameObject 會用重心座標把顏色內插到整個三角形。反光點如果剛好落在三角形中間、不在頂點上，就會被漏掉。
- **Phong**：vertex shader 只負責傳出世界座標和法向量，fragment shader 拿到內插後的法向量，在每個像素重新算光照，所以反光點最清楚。

### 4. 追蹤框架程式碼的發現

渲染一個三角形的流程（`GameObject::Draw`）：

1. `material.vertexShader()` 回傳 `Vector4[][]`：**第 0 個一定是頂點位置**（裁剪空間座標），後面的都是要內插的 varying
2. 除以 w 得到螢幕座標，用 `findBoundBox` 找出要掃描的範圍
3. 對範圍內每個像素：用 `pnpoly` 判斷是否在三角形內 → 用 `barycentric` 算權重 → 用 `interpolation` 把每個 varying 內插
4. `material.fragmentShader()` 拿到「螢幕位置 + 內插後的 varying」算出顏色
5. 深度比目前的小才寫入像素（深度測試）

所以要新增一種著色方式，只要在 Material 決定「要傳什麼 attribute 和 uniform」，在 vertex shader 決定「要內插什麼」，在 fragment shader 用內插結果算顏色。Flat 和 Gouraud 都是照這個架構，在 Material 傳入法向量、Model 矩陣、顏色和光照係數。

### 5. Bonus：貼圖著色器

新增 `TextureMaterial`、`TextureVertexShader`、`TextureFragmentShader`，並把它加進材質按鈕的切換順序。

- **找貼圖**：依模型名稱到 `data/Textures/` 找同名的圖片，例如 `cat.obj` → `cat.jpg`、`Elon_Musk_head.obj` → `Elon_Musk_head.bmp`。找不到就用 `Checkerboard.png` 棋盤格，方便看出 UV 的分布
- **Vertex shader**：除了位置和法向量，多傳出每個頂點的 UV
- **Fragment shader**：用透視校正後內插的 UV 到圖片上取顏色。UV 超出 [0, 1] 時重複貼圖，而且圖片的 y 軸往下、UV 的 v 往上，所以要用 `1 - v`。取出的顏色當作 albedo，再套用 Phong 光照，所以貼圖也會有明暗和反光

這裡剛好能看出透視校正的重要性：沒有校正的話，貼圖在斜面上會明顯扭曲。

### 6. 發現與修正的問題

| 問題 | 原因 | 修正 |
|---|---|---|
| Mac 上載入模型後名稱是完整路徑 | `GameObject` 只用 Windows 的 `\` 切路徑 | 改成同時支援 `\` 和 `/` |
| 選取物體時，物體顏色被改成光的顏色 | Inspector 用 `basic_light.light_color` 初始化物體顏色滑桿 | 改用物體自己的 `albedo` |
| 切換選取的物體後，材質按鈕顯示錯誤名稱 | 按鈕名稱沒有跟著物體更新 | 選取時依照物體目前的材質設定名稱 |
| 物體非等比例縮放時，光照方向錯誤 | 法向量直接乘 Model 矩陣，縮放後就不再垂直於表面 | 改用 Model 矩陣的**反轉置矩陣**轉換法向量 |
| 三角形有頂點跑到相機後面時，畫出錯誤的大三角形 | w < 0 的點除以 w 後會翻到畫面前方 | 這種三角形直接略過 |

## 測試

除了在 Processing 上實際操作，也用自動測試檢查：

- **重心座標**：2000 個隨機三角形和點，透視校正後的權重和 3D 中的真實權重一致
- **光照**：正對光源最亮；背對光源只剩環境光（0.27 = 0.3 × 0.9）；反光點在反射方向對準相機時最亮；光的強度調高時顏色不會超過 1
- **相機控制**：500 組隨機角度和距離，相機都正確看向原點
- 其他沿用 Lab 3 的測試（投影矩陣、View 矩陣、Model 矩陣）

## LLM 使用說明

本作業使用 **Claude** 協助完成：

- **理解作業**：請 Claude 說明作業要求，以及透視校正、三種著色方式、貼圖取樣的原理
- **撰寫程式**：在 Claude 的協助下完成各個函式的實作，以及框架 bug 的修正
- **測試**：Claude 協助撰寫自動測試，我則在自己的電腦上用 Processing 執行並截圖
- **撰寫 README**：README 的架構和演算法說明由 Claude 協助整理
