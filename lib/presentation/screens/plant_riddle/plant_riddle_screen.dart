import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/core/constants/app_images.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/map/map_state.dart';
import 'package:plantgo/presentation/blocs/riddle/riddle_bloc.dart';
import 'package:plantgo/presentation/blocs/riddle/riddle_event.dart';
import 'package:plantgo/presentation/blocs/riddle/riddle_state.dart';
import 'package:plantgo/presentation/screens/scanner/plant_scanner_screen.dart';

class PlantRiddleScreen extends StatefulWidget {
  final int levelIndex;

  const PlantRiddleScreen({
    Key? key,
    required this.levelIndex,
  }) : super(key: key);

  @override
  State<PlantRiddleScreen> createState() => _PlantRiddleScreenState();
}

class _PlantRiddleScreenState extends State<PlantRiddleScreen> {
  late RiddleBloc _riddleBloc;

  @override
  void initState() {
    super.initState();
    // Initialize map
    context.read<MapCubit>().initializeMap();
    
    // Initialize riddle bloc and load riddle for current level
    _riddleBloc = getIt<RiddleBloc>();
    _riddleBloc.add(LoadRiddleByLevel(levelIndex: widget.levelIndex));
  }

  @override
  void dispose() {
    _riddleBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Plant Riddle - Level ${widget.levelIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocProvider<RiddleBloc>.value(
        value: _riddleBloc,
        child: BlocBuilder<RiddleBloc, RiddleState>(
          builder: (context, riddleState) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.riddleBackground),
                  fit: BoxFit.fill, // Fill to ensure background covers entire screen
                ),
              ),
              child: SafeArea(
                child: _buildContent(riddleState),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(RiddleState riddleState) {
    if (riddleState is RiddleLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }
    
    if (riddleState is RiddleError) {
      return _buildErrorContent(riddleState.message);
    }
    
    if (riddleState is RiddleLoaded) {
      return _buildRiddleContent(riddleState);
    }
    
    return _buildComingSoonContent();
  }

  Widget _buildRiddleContent(RiddleLoaded state) {
    final riddle = state.riddle;

    return BlocBuilder<MapCubit, MapState>(
      builder: (context, mapState) {
        final size = MediaQuery.of(context).size;  // get screen dimensions
        return Stack(
          children: [
            // Scientific name positioned dynamically
            Positioned(
              top: size.height * 0.2,
              left: size.width * 0.05,
              // right: size.width * 0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.transparent, // Transparent to show background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Text(
                    //   'Scientific name',
                    //   style: TextStyle(
                    //     color: Colors.black87,
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //     shadows: [
                    //       Shadow(
                    //         offset: const Offset(1, 1),
                    //         blurRadius: 2,
                    //         color: Colors.white.withOpacity(0.8),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    Text(
                      riddle.plantScientificName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // if (riddle.plantCommonName.isNotEmpty) ...[
                    //   const SizedBox(height: 4),
                    //   Text(
                    //     '(${riddle.plantCommonName})',
                    //     style: TextStyle(
                    //       color: Colors.black54,
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.w500,
                    //       shadows: [
                    //         Shadow(
                    //           offset: const Offset(1, 1),
                    //           blurRadius: 2,
                    //           color: Colors.white.withOpacity(0.8),
                    //         ),
                    //       ],
                    //     ),
                    //     textAlign: TextAlign.center,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
            
            // Riddle part positioned dynamically
            Positioned(
              top: size.height * 0.25,
              left: size.width * 0.03,
              right: size.width * 0.05,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.transparent, // Transparent to show background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Riddle part',
                    //   style: TextStyle(
                    //     color: Colors.black87,
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w600,
                    //     shadows: [
                    //       Shadow(
                    //         offset: const Offset(1, 1),
                    //         blurRadius: 2,
                    //         color: Colors.white.withOpacity(0.8),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 12),
                    Text(
                      riddle.riddleText,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                    if (riddle.hint != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hint: ${riddle.hint}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Scan button positioned dynamically
            Positioned(
              bottom: size.height * 0.1,
              left: size.width * 0.05,
              right: size.width * 0.05,
              child: SizedBox(
                height: size.height * 0.07,
                child: ElevatedButton(
                  onPressed: () => _startScanning(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                    shadowColor: Colors.green.withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Start Plant Scanner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _riddleBloc.add(LoadRiddleByLevel(levelIndex: widget.levelIndex));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.construction,
                  color: Colors.amber,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Level ${widget.levelIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Coming Soon!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This riddle level is under development.\nCheck back soon for new challenges!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startScanning(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlantScannerScreen(),
      ),
    );
  }
}
