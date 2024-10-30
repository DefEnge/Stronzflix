import 'package:flutter/material.dart';

class FloatingPlayerContext extends StatefulWidget {
    final Widget? child;

    const FloatingPlayerContext({
        required this.child,
        super.key
    });

    @override
    State<FloatingPlayerContext> createState() => FloatingPlayerContextState();

    static FloatingPlayerContextState of(BuildContext context) {
        return context.findAncestorStateOfType<FloatingPlayerContextState>()!;
    }
}

class FloatingPlayerContextState extends State<FloatingPlayerContext> {

    Offset _position = const Offset(100.0, 100.0);
    Offset _initialPosition = const Offset(100.0, 100.0);
    Offset _dragOffset = Offset.zero;

    Size _size = const Size(16 * 15, 9 * 15);
    final Size _minSize = const Size(16 * 10, 9 * 10);
    final double _padding = 20.0;

    bool _visible = false;
    bool _showControls = false;
    bool _resizing = false;

    Widget Function(BuildContext)? _buildContent;
    void Function()? _onClose;
    
    void show(Widget Function(BuildContext)? buildContent, {void Function()? onClose}) {
        super.setState(() {
            this._buildContent = buildContent;
            this._onClose = onClose;
            this._visible = true;
        });
    }

    Widget _buildControls(BuildContext context) {
        return Stack(
            children: [
                Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [
                                0.0,
                                0.2,
                            ],
                            colors: [
                                Color(0x61000000),
                                Color(0x00000000),
                            ],
                        )
                    )
                ),
                Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [
                                0.5,
                                1.0,
                            ],
                            colors: [
                                Color(0x00000000),
                                Color(0x61000000),
                            ],
                        )
                    )
                ),
                Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                            this._onClose?.call();
                            super.setState(() => this._visible = false);
                        },
                    ),
                ),
                Align(
                    alignment: Alignment.bottomLeft,
                    child: GestureDetector(
                        onPanStart: (_) => super.setState(() => this._resizing = true),
                        onPanEnd: (_) => super.setState(() => this._resizing = false),
                        onPanUpdate: (details) {
                            super.setState(() {
                                double aspectRatio = this._size.width / this._size.height;

                                double newWidth = this._size.width - details.delta.dx;

                                double clampedWidth = newWidth.clamp(this._minSize.width, double.infinity);
                                double clampedHeight = clampedWidth / aspectRatio;

                                double widthDelta = this._size.width - clampedWidth;

                                this._size = Size(clampedWidth, clampedHeight);
                                this._position = Offset(
                                    this._position.dx + widthDelta,
                                    this._position.dy
                                );
                            });
                        },
                        child: const Icon(
                            Icons.drag_handle
                        )
                    ),
                ),
            ],
        );
    }

    Widget _buildFloatintPlayer(BuildContext context) {
        return Positioned(
            left: this._position.dx,
            top: this._position.dy,
            child: MouseRegion(
                onEnter: (_) => super.setState(() => this._showControls = true),
                onExit: (_) => super.setState(() => this._showControls = this._resizing || false),
                child: GestureDetector(
                    child: Container(
                        width: this._size.width,
                        height: this._size.height,
                        decoration: BoxDecoration(
                            boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                                children: [
                                    this._buildContent!.call(context),
                                    if (this._showControls)
                                        this._buildControls(context)
                                ],
                            ),
                        ),
                    ),
                    onPanDown: (details) {
                        this._dragOffset = details.localPosition;
                        this._initialPosition = this._position;
                    },
                    onPanUpdate: (details) {
                        super.setState(() {
                            Offset newPosition = Offset(
                                this._initialPosition.dx + details.localPosition.dx - this._dragOffset.dx,
                                this._initialPosition.dy + details.localPosition.dy - this._dragOffset.dy
                            );

                            Size screenSize = MediaQuery.of(context).size;
                            double maxX = screenSize.width - this._size.width - this._padding;
                            double maxY = screenSize.height - this._size.height - this._padding;

                            this._position = Offset(
                                newPosition.dx.clamp(this._padding, maxX),
                                newPosition.dy.clamp(this._padding, maxY)
                            );
                        });
                    },
                )
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                if(super.widget.child != null)
                    super.widget.child!,
                if(this._visible)
                    this._buildFloatintPlayer(context)
            ],
        );
    }
}