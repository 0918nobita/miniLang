document.addEventListener('DOMContentLoaded', async () => {
  const canvas = document.getElementById('glcanvas');

  const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
  if (gl === null) return;

  // クリアカラーを黒色、不透明に設定する
  gl.clearColor(0.0, 0.0, 0.0, 1.0);

  // 深度テストを有効化
  gl.enable(gl.DEPTH_TEST);

  // 近くにある物体は、遠くにある物体を覆い隠す
  gl.depthFunc(gl.LEQUAL);

  // カラーバッファや深度バッファをクリアする
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  // gl.viewport(...) で描画解像度を変更できる

  const [vertexShader, fragmentShader] = await Promise.all(
    [
      loadShader(gl, gl.VERTEX_SHADER, 'vertex.glsl'),
      loadShader(gl, gl.FRAGMENT_SHADER, 'fragment.glsl'),
    ]
  );

  console.log({ vertexShader, fragmentShader });
});


async function loadShader(gl, shaderType, shaderFile) {
  const shader = gl.createShader(shaderType);

  const res = await fetch(shaderFile);
  if (res.status !== 200) throw new Error('指定されたファイルが見つかりません');

  const shaderSource = await res.text();

  gl.shaderSource(shader, shaderSource);
  gl.compileShader(shader);

  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    throw new Error(`シェーダのコンパイルに失敗しました (${shaderFile})`);
  }

  return shader;
}


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
  頂点配列の生成
  頂点配列: 3D 空間での頂点の位置のような頂点属性を含んでいる配列
  それらの情報は、JavaScript を用いて以下のうち１つまたは複数の方法で生成される：
    - 例えば .obj ファイルのような、3D モデルを表現するファイルを処理する
    - 手続き的に 1 からデータを生成する
    - 幾何学的図形の頂点配列を提供するライブラリを利用する

  頂点配列内のそのデータは１つまたは複数の頂点バッファを通じて GPU に渡される。
  描画ジョブが送られたときには、加えてインデックス配列(頂点配列の要素を指すもの)を供給する必要もある。
  インデックス配列: 頂点がどのように三角形に集められるかをコントロールするための配列

  GPU は、選択されたそれぞれの頂点を読み込み、それを頂点シェーダに通すことから処理を始める。
  頂点シェーダ: 頂点属性のセットを入力として受け取り、新しい属性のセットを出力するプログラム
    最低限であれば画面空間内で投影される位置のみを計算するが、色やテクスチャの座標のような他の属性も生成できる。

  その後 GPU は、三角形を作り出すために投影される頂点同士を接続する。
  インデックス配列によって指定された順序で頂点を取り出し、３つずつグループ化することで行われる。

  ラスタライザはそれぞれの三角形を取り出し、切り抜き、画面外に来る部分を除去した上で、
  残っていて見える部分をピクセル単位のフラグメントに分解する。
  他の頂点属性のための頂点シェーダの出力は、各三角形のラスタライズされたサーフェスを通して補間もされる。
  その間、各フラグメントに対してなめらかなグラデーションが適用される。
  例えば、頂点シェーダが色の値を各頂点に適用するなら、
  ラスタライザはピクセルに分割されたサーフェス上で適切なカラーグラデーションをその色にブレンドするだろう。

  生成されたピクセル単位のフラグメントはその後、フラグメントシェーダと呼ばれるプログラムを通される。
  フラグメントシェーダは各ピクセルに対してカラーと深度の値を出力し、後にそれらはフレームバッファに描画される。
  一般的なフラグメントシェーダによる操作は、テクスチャマッピングと発光である。
  フラグメントシェーダは描画される各ピクセルに対して無関係に動作するため、より洗練された特別な効果を与えられる。
  しかし、グラフィックスパイプラインにおいてパフォーマンスによく影響する部分でもある。

  フレームバッファは、描画ジョブの出力のための最後の目的地
  フレームバッファは１つ以上の 2D 画像
    １つまたはそれ以上のカラーバッファに加えて、フレームバッファは深度バッファあるいはステンシルバッファを持つことができる
    どちらもフラグメントがフレームバッファに描画される前にフィルタリングするオプションのバッファ

  深度テストによって、すでに後ろに描画されたオブジェクトのフラグメントは捨てられる。
  そしてステンシルテストでは、フレームバッファにおいて描画可能な部分を強制するためにステンシルバッファに描画される図形を、
  その描画ジョブを「型抜き」しながら用いる。
  これら２つのフィルターで生き残ったフラグメントは、アルファ値をブレンドして上書きした色の値を持つ。
  最終的なカラー、深度、ステンシル値は対応するバッファに描画される。
  その出力は、他の描画ジョブへのテクスチャ入力として用いることもできる。
*/
