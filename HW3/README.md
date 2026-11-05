# CG Assignments - Lab 3

## 完成項目

| 項目 | 檔案 / 函式 | 狀態 |
|---|---|---|
| 前置：貼上 HW1、HW2 的程式 | `util.pde`、`Matrix4.pde` | ✅ 完成 |
| 旋轉矩陣（x、y 軸） | `Matrix4::makeRotX`、`makeRotY` | ✅ 完成 |
| Model 矩陣 | `GameObject::localToWorld` | ✅ 完成 |
| View 矩陣 | `Camera::setPositionOrientation` | ✅ 完成 |
| Projection 矩陣 | `Camera::setSize` | ✅ 完成 |
| 深度緩衝 | `util::getDepth` | ✅ 完成 |
| 相機控制 | `HW3::cameraControl` | ✅ 完成 |
| 背面剔除 | `GameObject::debugDraw` | ✅ 完成 |
| **Bonus：3D 裁剪** | `GameObject::drawClippedLine` | ✅ 完成 |

## 執行截圖

![screenshot](screenshot.png)

## 操作方式

- 左上角第一個按鈕：載入 `.obj` 模型（範例在 `data/Meshes/`）
- 左上角第二個按鈕：開關 debug 線框
- 相機控制：
  - **A / D**：左右繞著模型轉
  - **W / S**：上下繞著模型轉
  - **Q / E**：拉近 / 拉遠
  - **在畫布上拖曳滑鼠**：旋轉視角
  - **滾輪（觸控板兩指上下滑）**：拉近 / 拉遠

## 實作方式

### 1. 旋轉矩陣

繞哪一軸旋轉，那一軸的座標就不變，另外兩軸用 cos、sin 做 2D 旋轉：

```
RotX:                 RotY:                 RotZ:
| 1  0    0    0 |    |  cos 0 sin 0 |      | cos -sin 0 0 |
| 0  cos -sin  0 |    |  0   1 0   0 |      | sin  cos 0 0 |
| 0  sin  cos  0 |    | -sin 0 cos 0 |      | 0    0   1 0 |
| 0  0    0    1 |    |  0   0 0   1 |      | 0    0   0 1 |
```

**Yaw、Pitch、Roll**：這個框架用 **y 軸代表上下**，所以：
- 繞 **y 軸**（RotY）是 **Yaw**：左右轉頭
- 繞 **x 軸**（RotX）是 **Pitch**：抬頭、低頭
- 繞 **z 軸**（RotZ）是 **Roll**：歪頭

和 HW2 模板註解寫的不同，因為 HW2 是 2D，沒有區分哪一軸朝上。

### 2. Model 矩陣

```java
Trans(position) × RotY(rot.y) × RotX(rot.x) × RotZ(rot.z) × Scale(scale)
```

套到點上時從右邊開始算：**先縮放 → 再旋轉 → 最後平移**。

**發現**：框架已經寫好 `worldToLocal()`，它是 `Scale⁻¹ × RotZ⁻¹ × RotX⁻¹ × RotY⁻¹ × Trans⁻¹`。反矩陣的順序會顛倒，所以反推回來就能確定 `localToWorld()` 的旋轉順序必須是 Y → X → Z。我用測試確認了 `worldToLocal() × localToWorld()` 是單位矩陣。

### 3. View 矩陣（相機）

給相機位置 `pos` 和看向的點 `lookat`，建立相機自己的三個座標軸：

1. **forward**（前）= `normalize(lookat - pos)`
2. **right**（右）= `normalize(cross(up, forward))`，其中 `up = (0, 1, 0)`
3. **camUp**（上）= `cross(forward, right)`

View 矩陣的三列就是這三個軸，第四欄是 `-dot(軸, pos)`，作用是先把相機移到原點、再旋轉到相機的方向：

```
| right.x   right.y   right.z   -dot(right, pos)   |
| camUp.x   camUp.y   camUp.z   -dot(camUp, pos)   |
| forward.x forward.y forward.z -dot(forward, pos) |
| 0         0         0          1                 |
```

相機從正上方或正下方往下看時，`forward` 和 `up` 平行，外積會是 0，這時改用 `(0, 0, 1)` 當作 up，避免除以 0。

### 4. Projection 矩陣（透視投影）

```
| f/aspect  0   0             0            |
| 0         f   0             0            |
| 0         0   (far+near)/(far-near)  -2·far·near/(far-near) |
| 0         0   1             0            |
```

- `f = 1 / tan(FOV / 2)`：視角越小，畫面放大越多
- `aspect = 寬 / 高`：避免畫面被拉長
- 第三列把 z 從 `[near, far]` 映射到 `[-1, 1]`
- 第四列讓 `w = z`，之後除以 w，**越遠的東西就越小**，這就是透視效果

框架的 `inverseProjection()` 已經寫好，從它用到的矩陣位置（`m[0]、m[5]、m[10]、m[11]、m[14]`）可以反推出投影矩陣的形式。測試確認：near 平面的點投影後 z = -1，far 平面 z = 1，剛好在視角邊緣的點 x = 1。

### 5. 深度緩衝：`getDepth`

三角形投影到螢幕後仍然是平面，而且**除以 w 之後的 z（NDC 深度）在螢幕上是線性的**，所以可以直接用 2D 重心座標內插：

1. 算出點 (x, y) 在三角形上的重心座標 (α, β, γ)，也就是三個小三角形面積佔大三角形的比例
2. 深度 `z = α·z₀ + β·z₁ + γ·z₂`

**「結果不太明顯，為什麼？」**：透視投影後的深度不是線性的。這裡 near = 0.1、far = 1000，深度大部分的精度都集中在非常靠近相機的地方。模型在距離 10 左右時，深度已經約是 0.98，所以畫出來幾乎都是接近白色，看不太出深淺差異。

### 6. 相機控制

做成**環繞相機（Orbit Camera）**：相機永遠看著原點，用水平角度 `yaw`、垂直角度 `pitch` 和距離 `distance` 決定位置：

```java
x = distance × cos(pitch) × sin(yaw)
y = distance × sin(pitch)
z = -distance × cos(pitch) × cos(yaw)
```

`yaw = pitch = 0` 時剛好是原本的相機位置 (0, 0, -10)。`pitch` 限制在 ±1.5（約 ±86°），避免轉到正上方時畫面翻轉。只有滑鼠在畫布範圍內拖曳時才旋轉，不會影響右邊的滑桿。

### 7. 背面剔除（Backculling）

對每個三角形：

1. 把三個頂點轉到世界座標
2. 用外積算出面的法向量 `n = (v1 - v0) × (v2 - v0)`。obj 檔的頂點是逆時針排列，所以這個法向量朝外
3. 如果 `dot(n, v0 - 相機位置) >= 0`，代表法向量和「相機看過去的方向」同向，**這個面背對相機**，就不畫

測試：從正前方看 `cube.obj` 的 12 個三角形，只剩正面的 2 個被畫出來。

### 8. Bonus：3D 裁剪

在**裁剪空間**（乘上 MVP 後、除以 w 之前）裁剪每條線段。視體的六個平面是：

```
-w ≤ x ≤ w,   -w ≤ y ≤ w,   -w ≤ z ≤ w
```

改寫成六個「要 ≥ 0」的值：`w+x、w-x、w+y、w-y、w+z、w-z`。對每個平面：

- 兩端都 < 0：整條線在外面，丟掉
- 一端 < 0：算出交點 `t = d₀ / (d₀ - d₁)`，從外面進來就更新起點，從裡面出去就更新終點

六個平面都處理完後，只畫 `t` 在起點和終點之間的那一段。

**為什麼要在除以 w 之前裁剪**：在相機後面的點 w < 0，除以 w 之後會被翻到畫面前方，畫出錯誤的線。在裁剪空間就先把這些部分切掉，才不會出錯。基於同樣的原因，填色時我也略過有頂點在相機後面的三角形。

### 對框架的修改

- **畫面上下翻轉**：NDC 的 y 往上是正的，但影像的列是往下排的，原本的模板畫出來會上下顛倒。我把 `Draw()` 寫入像素的位置和 `debugDraw()` 的 y 映射改成上下翻轉，和 Lab 4 模板的寫法一致。

## 測試

除了在 Processing 上實際操作，也用自動測試檢查：

- 投影矩陣：near / far 平面和視角邊緣的映射正確
- View 矩陣：1000 組隨機相機位置，看向的點都會落在相機正前方
- Model 矩陣：500 組隨機變換，`worldToLocal() × localToWorld()` 都是單位矩陣
- `getDepth`：2000 個隨機三角形，內插出的深度和實際投影結果一致
- 背面剔除：`cube.obj` 從正面看只剩 2 個三角形
- 3D 裁剪：在框內的線段保持不變；穿過邊界的線段被切在邊界上；完全在外面或跑到相機後面的部分都被正確處理

## LLM 使用說明

本作業使用 **Claude** 協助完成：

- **理解作業**：請 Claude 說明作業要求，以及 MVP 矩陣、深度緩衝、背面剔除、3D 裁剪的原理
- **撰寫程式**：在 Claude 的協助下完成各個函式的實作
- **測試**：Claude 協助撰寫自動測試，我則在自己的電腦上用 Processing 執行並截圖
- **撰寫 README**：README 的架構和演算法說明由 Claude 協助整理
