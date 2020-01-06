attribute vec3 position; // 3 次元ベクトル
attribute vec4 color;    // 色は 4 次元 (RGBA) ベクトル

varying vec4 vColor; // フラグメントシェーダに渡す値

uniform mat4 mvpMatrix; // 座標変換マトリクス

void main(void) {
  // フラグメントシェーダへ値を渡す
  vColor = color;

  // 渡された頂点座標を、変換行列を用いてワールド空間座標に変換
  gl_Position = mvpMatrix * vec4(position, 1.0);
}
