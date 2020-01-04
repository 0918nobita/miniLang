document.addEventListener('DOMContentLoaded', () => {
  const canvas = document.getElementById('glcanvas');

  const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
  if (gl === null) return;

  console.log(gl);

  // クリアカラーを黒色、不透明に設定する
  gl.clearColor(0.0, 0.0, 0.0, 1.0);

  // 深度テストを有効化
  gl.enable(gl.DEPTH_TEST);

  // 近くにある物体は、遠くにある物体を覆い隠す
  gl.depthFunc(gl.LEQUAL);

  // カラーバッファや深度バッファをクリアする
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  // gl.viewport(...) で描画解像度を変更できる

  /*
    【WebGL とは】
    WebGL は、専らブラウザ上で、インテラクティブ3Dグラフィックスを実装可能にする JavaScript API。
    canvas 要素の特定のコンテキストとして動作し、ハードウェアアクセラレーションの有効な3Dレンダリングへの
    JavaScript を介してアクセスできるようになる。
    canvas 要素内で動作するため、WebGL は完全な DOM インターフェースを持つ。
    API は OpenGL ES 2.0 に基づいており、これは WebGL があらゆる多くの異なるデバイスで動作できることを意味する。

    【どのように WebGL が動作するか】
    グラフィックカードで直接動作するように設計されているため、低レベルであり他の Web 技術より難解。
    たくさんの計算を伴う複雑な 3D レンダリングを可能にしている。
    ある種のシーンをレンダリングすることを考えることが多い。
    そのシーンは複数の、後続する描画ジョブあるいは呼び出しを伴うことが多い。
    それらは GPU において「レンダリングパイプライン」と呼ばれるプロセスで実行される。
    WebGL でのモデル描画において、三角形は基本的な要素。
    WebGL による描画プロセスは、どこにどうやって三角形をどんな見た目(色、シェーダ、テクスチャ等)で
    描画するかを指定する情報を生成するために JavaScript を用いることに関与している。
    この情報はやがて GPU に渡され、処理され、シーンのビューが返される。

    【レンダリングパイプライン】
    JavaScript / WebGL program
    Vertex Buffers
    Vertex Shader
    Triangle Assembly
    Rasterizer
    Fragment Shader
    Frame Buffer
  */
});
