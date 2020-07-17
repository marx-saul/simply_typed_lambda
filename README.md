これは課題型付きラムダ計算の型検査器であり、提出される課題の全体です。

# コンパイル法
このプログラムはD言語で書かれており、dmdコンパイラv2.092.0で正常に動作することを確認しています。

<code>dmd .../source/app.d .../source/check.d .../source/defs.d .../source/parse.d -of=checker.exe</code> とすれば、実行可能ファイル <code>checker.exe</code> がビルドされます。

パッケージ管理ソフトウェアであるdubを使う場合、<code>dub run</code> で実行可能です。もしくは、このフォルダで <code>dub build</code> と打てば、実行可能ファイル <code>./simply_typed_lambda</code> がビルドされます。

# 例
<code>
\f:int->int->int.\x:int.\y:int.f x y

Well typed: ((int -> (int -> int)) -> (int -> (int -> int)))
</code>
