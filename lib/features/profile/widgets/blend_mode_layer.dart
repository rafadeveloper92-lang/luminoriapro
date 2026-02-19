import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Aplica [BlendMode.screen] ao filho ao compor com o conteúdo abaixo.
/// Usado para vídeos VFX com fundo preto: o preto fica invisível e só o efeito se vê.
class BlendModeLayer extends SingleChildRenderObjectWidget {
  const BlendModeLayer({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderBlendModeLayer();
  }
}

class RenderBlendModeLayer extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.canvas.saveLayer(
      offset & size,
      Paint()..blendMode = BlendMode.screen,
    );
    context.paintChild(child!, offset);
    context.canvas.restore();
  }
}
