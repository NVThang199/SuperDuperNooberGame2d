import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final data = await rootBundle.load('assets/images/ui/inventory/Inventory1.png');
  final bytes = data.buffer.asUint8List();
  final image = await decodeImageFromList(bytes);
  
  print('Inventory1.png: ${image.width}x${image.height}');
  
  runApp(MaterialApp(
    home: CoordinateFinder(imageBytes: bytes),
  ));
}

class CoordinateFinder extends StatefulWidget {
  final Uint8List imageBytes;
  const CoordinateFinder({required this.imageBytes, super.key});
  
  @override
  State<CoordinateFinder> createState() => _CoordinateFinderState();
}

class _CoordinateFinderState extends State<CoordinateFinder> {
  Offset? _clickPos;
  final TransformationController _transformController = TransformationController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Click inventory slots to measure')),
      body: InteractiveViewer(
        transformationController: _transformController,
        child: GestureDetector(
          onTapDown: (details) {
            setState(() {
              _clickPos = details.localPosition;
              final scale = _transformController.value.getMaxScaleOnAxis();
              print('Click at: ${_clickPos!.dx.toInt()}, ${_clickPos!.dy.toInt()} (raw)');
              print('Scaled to: ${(_clickPos!.dx / scale).toInt()}, ${(_clickPos!.dy / scale).toInt()} (on 147x84)');
            });
          },
          child: Image.memory(
            widget.imageBytes,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
      bottomSheet: _clickPos != null
        ? Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Text(
              'Raw: ${_clickPos!.dx.toInt()}, ${_clickPos!.dy.toInt()}\n'
              'On 147x84: ${(_clickPos!.dx / _transformController.value.getMaxScaleOnAxis()).toInt()}, '
              '${(_clickPos!.dy / _transformController.value.getMaxScaleOnAxis()).toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : null,
    );
  }
}
