import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juara_cpns/class/app_router.dart';
import 'package:juara_cpns/class/platform_ui.dart';
import 'package:juara_cpns/class/question_model.dart';
import 'package:juara_cpns/class/responsive_layout.dart';
import 'package:juara_cpns/screens/result_screen.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class TryoutScreen extends StatefulWidget {
  final String type;
  final String? packageId;
  final Set<String> markedQuestions = {};

  TryoutScreen({
    super.key,
    required this.type,
    this.packageId,
  });

  @override
  _TryoutScreenState createState() => _TryoutScreenState();
}

class _TryoutScreenState extends State<TryoutScreen> with SingleTickerProviderStateMixin {
  List<Question> questions = [];
  Map<String, String> userAnswers = {};
  int currentQuestionIndex = 0;
  Timer? timer;
  int remainingSeconds = 0;
  bool isLoading = true;
  String? errorMessage;
  int totalQuestions = 0;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool canSubmit = false;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  bool _submitting = false;

  // Scroll controller for the question indicators
  final ScrollController _indicatorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Setup animation controller for transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn)
    );

    loadPackageAndQuestions();
  }

  Future<void> loadPackageAndQuestions() async {
    try {
      // First, get the package details to know the total question count
      if (widget.packageId != null) {
        final packageDoc = await FirebaseFirestore.instance
            .collection('practice_packages')
            .doc(widget.packageId)
            .get();

        if (packageDoc.exists) {
          setState(() {
            totalQuestions = packageDoc.data()?['questionCount'] ?? 0;
          });
        }
      }

      // Then load the questions
      await loadQuestions();
    } catch (e) {
      print('Error loading package details: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan saat memuat paket: ${e.toString()}';
      });
    }
  }

  Future<void> loadQuestions() async {
    try {
      Query query = FirebaseFirestore.instance.collection('questions');

      if (widget.packageId != null) {
        query = query.where('packageId', isEqualTo: widget.packageId);
      } else {
        query = query
            .where('type', isEqualTo: widget.type)
            .limit(totalQuestions > 0 ? totalQuestions : 30);
      }

      final questionsSnapshot = await query.get();
      print('Found ${questionsSnapshot.docs.length} questions');

      if (questionsSnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Tidak ada soal tersedia untuk saat ini';
        });
        return;
      }

      // Create list of questions
      List<Question> loadedQuestions = questionsSnapshot.docs
          .map((doc) => Question.fromMap(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // Shuffle the questions
      loadedQuestions.shuffle();

      // Ensure we don't exceed totalQuestions
      if (totalQuestions > 0 && loadedQuestions.length > totalQuestions) {
        loadedQuestions = loadedQuestions.sublist(0, totalQuestions);
      }

      setState(() {
        questions = loadedQuestions;
        isLoading = false;

        // Update totalQuestions if it wasn't set from package
        if (totalQuestions == 0) {
          totalQuestions = questions.length;
        }

        startTimer();
      });

      // Start the fade-in animation
      _animationController?.forward();
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan saat memuat soal: ${e.toString()}';
      });
    }
  }

  void _scrollToCurrentQuestion() {
    if (_indicatorScrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = screenWidth < 600 ? 45.0 : 50.0; // Adjusted for responsive design
      final targetPosition = (currentQuestionIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      _indicatorScrollController.animateTo(
        targetPosition > 0 ? targetPosition : 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> submitAnswers() async {
    if (userId.isEmpty) return;

    setState(() {
      _submitting = true;
    });

    try {
      // Calculate scores
      Map<String, int> scores = {};
      int twkScore = 0, tiuScore = 0, tkpScore = 0;

      for (var question in questions) {
        final userAnswer = userAnswers[question.id];
        if (userAnswer == null) continue;

        if (question.type == 'TKP') {
          tkpScore += question.tkpScoring[userAnswer] ?? 0;
        } else {
          if (userAnswer == question.correctAnswer) {
            if (question.type == 'TWK') {
              twkScore += 5;
            } else if (question.type == 'TIU') {
              tiuScore += 5;
            }
          }
        }
      }

      scores = {
        'TWK': twkScore,
        'TIU': tiuScore,
        'TKP': tkpScore,
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('user_answers')
          .doc('${userId}_${widget.packageId ?? widget.type}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'userId': userId,
        'packageId': widget.packageId,
        'type': widget.type,
        'answers': userAnswers,
        'scores': scores,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Display a success animation before navigating
      if (mounted) {
        // Fade out the current content
        await _animationController?.reverse();

        // Navigate to result screen
        Navigator.pushReplacementNamed(
          context,
          AppRouter.result,
          arguments: {
            'questions': questions,
            'userAnswers': userAnswers,
            'scores': scores,
            'type': widget.type,
          },
        );
      }
    } catch (e) {
      setState(() {
        _submitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting answers: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> saveProgress() async {
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_progress')
          .doc('${userId}_${widget.packageId ?? widget.type}')
          .set({
        'userId': userId,
        'packageId': widget.packageId,
        'type': widget.type,
        'answers': userAnswers,
        'markedQuestions': widget.markedQuestions.toList(),
        'lastQuestionIndex': currentQuestionIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void startTimer() {
    // Set duration based on question type
    int duration;
    switch (widget.type) {
      case 'TWK':
        duration = 30 * 60; // 30 minutes
        break;
      case 'TIU':
        duration = 35 * 60; // 35 minutes
        break;
      case 'TKP':
        duration = 35 * 60; // 35 minutes
        break;
      default:
        duration = 100 * 60; // 100 minutes for full tryout
    }

    remainingSeconds = duration;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          // Time's up - show dialog
          _showTimeUpDialog();
        }
      });
    });
  }

  void _showTimeUpDialog() {
    if (timer?.isActive ?? false) {
      timer?.cancel();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Waktu Habis'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/timer_end.json',
              width: 120,
              height: 120,
              repeat: false,
            ),
            const SizedBox(height: 16),
            const Text('Waktu mengerjakan soal telah habis. Jawaban Anda akan dikumpulkan secara otomatis.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              submitAnswers();
            },
            child: const Text('Kumpulkan'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  double _calculateProgress() {
    if (questions.isEmpty) return 0.0;
    return userAnswers.length / questions.length;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes < 5) {
      // If less than 5 minutes, use red color
      return '<span style="color: #F44336">${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}</span>';
    }

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (errorMessage != null) {
      return _buildErrorScreen();
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tryout ${widget.type}'),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Tidak ada soal tersedia'),
        ),
      );
    }

    // Schedule the scroll to current question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentQuestion();
    });

    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobileLayout: _buildMobileLayout(),
          desktopLayout: _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final question = questions[currentQuestionIndex];

    return Column(
      children: [
        _buildHeader(isMobile: true),
        _buildProgressIndicator(),
        _buildQuestionIndicators(scrollable: true),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildQuestionCard(question),
            ),
          ),
        ),
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final question = questions[currentQuestionIndex];

    return Row(
      children: [
        // Left sidebar with question indicators and timer
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(isMobile: false),
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildQuestionIndicators(scrollable: false, isVertical: true),
                ),
              ),
            ],
          ),
        ),

        // Main question area
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildQuestionCard(question),
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Mempersiapkan soal ${widget.type}...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE0E0E0),
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tryout ${widget.type}'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: CustomCard(
          padding: const EdgeInsets.all(24),
          hasShadow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/error_illustration.svg',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: AppTheme.textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              CustomButton(
                disabled: false,
                text: 'Kembali',
                isPrimary: true,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRouter.home,
                    );
                  }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 20.0,
          vertical: isMobile ? 12.0 : 16.0
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tryout ${widget.type}',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildTimerWidget(isMobile),
        ],
      ),
    );
  }

  Widget _buildTimerWidget(bool isMobile) {
    // Calculate percentage for circle
    final totalTime = widget.type == 'FULL' ? 100 * 60 : 35 * 60;
    final percentage = remainingSeconds / totalTime;

    // Determine color based on time remaining
    Color timerColor = AppTheme.successColor;
    if (remainingSeconds < 300) { // Less than 5 minutes
      timerColor = AppTheme.errorColor;
    } else if (remainingSeconds < 600) { // Less than 10 minutes
      timerColor = AppTheme.warningColor;
    }

    if (isMobile) {
      // Simple display for mobile
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else {
      // Circular timer for desktop
      return CircularPercentIndicator(
        radius: 28.0,
        lineWidth: 5.0,
        percent: percentage,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${remainingSeconds ~/ 60}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
        progressColor: timerColor,
        backgroundColor: Colors.white.withOpacity(0.3),
        circularStrokeCap: CircularStrokeCap.round,
      );
    }
  }

  Widget _buildProgressIndicator() {
    final progressPercentage = _calculateProgress();

    return Column(
      children: [
        LinearPercentIndicator(
          percent: progressPercentage,
          lineHeight: 8,
          animation: true,
          animationDuration: 500,
          backgroundColor: Colors.grey[200],
          progressColor: AppTheme.successColor,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres',
                style: AppTheme.textTheme.bodySmall,
              ),
              Text(
                '${userAnswers.length}/$totalQuestions soal dijawab',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progressPercentage == 1.0
                      ? AppTheme.successColor
                      : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionIndicators({required bool scrollable, bool isVertical = false}) {
    Widget buildIndicatorGrid() {
      if (isVertical) {
        // Vertical grid for sidebar in desktop layout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Daftar Soal',
                style: AppTheme.textTheme.titleMedium,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildIndicators(),
            ),
            const SizedBox(height: 16),
            _buildIndicatorLegend(),
            const SizedBox(height: 16),
            CustomButton(
              disabled: false,
              text: widget.markedQuestions.contains(questions[currentQuestionIndex].id)
                  ? 'Hapus Tanda'
                  : 'Tandai Soal',
              icon: widget.markedQuestions.contains(questions[currentQuestionIndex].id)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              onPressed: () {
                setState(() {
                  if (widget.markedQuestions.contains(questions[currentQuestionIndex].id)) {
                    widget.markedQuestions.remove(questions[currentQuestionIndex].id);
                  } else {
                    widget.markedQuestions.add(questions[currentQuestionIndex].id);
                  }
                });
                saveProgress();
              },
              isPrimary: false,
            ),
          ],
        );
      } else if (scrollable) {
        // Scrollable horizontal list for mobile layout
        return Column(
          children: [
            Container(
              height: 50,
              child: ListView(
                controller: _indicatorScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _buildIndicators(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMarkButton(),
                    ],
                  ),
                  _buildCompactLegend(),
                ],
              ),
            ),
          ],
        );
      } else {
        // Standard grid layout
        return Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildIndicators(),
            ),
            const SizedBox(height: 8),
            _buildIndicatorLegend(),
          ],
        );
      }
    }

    return buildIndicatorGrid();
  }

  List<Widget> _buildIndicators() {
    return List.generate(
      questions.length,
          (index) {
        final question = questions[index];
        Color backgroundColor;
        Color textColor = Colors.white;
        IconData? iconData;

        if (widget.markedQuestions.contains(question.id)) {
          backgroundColor = AppTheme.warningColor; // Marked question
          iconData = Icons.bookmark;
        } else if (userAnswers.containsKey(question.id)) {
          backgroundColor = AppTheme.successColor; // Answered
        } else {
          backgroundColor = Colors.grey.shade300; // Unanswered
          textColor = Colors.black;
        }

        final isCurrentQuestion = index == currentQuestionIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              currentQuestionIndex = index;
            });

            // Animate to the selected question indicator
            _scrollToCurrentQuestion();
          },
          child: Container(
            width: 45,
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: isCurrentQuestion
                  ? Border.all(color: AppTheme.primaryColor, width: 2.5)
                  : null,
              boxShadow: isCurrentQuestion
                  ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (iconData != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      iconData,
                      size: 12,
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicatorLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keterangan:',
          style: AppTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildLegendItem(Colors.green, 'Sudah dijawab'),
        const SizedBox(height: 4),
        _buildLegendItem(Colors.orange, 'Ditandai'),
        const SizedBox(height: 4),
        _buildLegendItem(Colors.grey.shade300, 'Belum dijawab'),
      ],
    );
  }

  Widget _buildCompactLegend() {
    return Row(
      children: [
        _buildCompactLegendItem(AppTheme.successColor, 'Dijawab'),
        const SizedBox(width: 8),
        _buildCompactLegendItem(AppTheme.warningColor, 'Ditandai'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCompactLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMarkButton() {
    final isMarked = widget.markedQuestions.contains(questions[currentQuestionIndex].id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isMarked) {
            widget.markedQuestions.remove(questions[currentQuestionIndex].id);
          } else {
            widget.markedQuestions.add(questions[currentQuestionIndex].id);
          }
        });
        saveProgress();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMarked ? AppTheme.warningColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMarked ? AppTheme.warningColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMarked ? Icons.bookmark : Icons.bookmark_border,
              size: 16,
              color: isMarked ? AppTheme.warningColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isMarked ? 'Ditandai' : 'Tandai',
              style: TextStyle(
                fontSize: 12,
                color: isMarked ? AppTheme.warningColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return CustomCard(
      hasShadow: true,
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentQuestionIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getQuestionTypeColor(question.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              question.type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getQuestionTypeColor(question.type),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Soal ${currentQuestionIndex + 1} dari $totalQuestions',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Question content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildAnswerOptions(question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(Question question) {
    return Column(
      children: question.options.map((option) {
        final isSelected = userAnswers[question.id] == option;

        return GestureDetector(
          onTap: () {
            setState(() {
              userAnswers[question.id] = option;
              canSubmit = userAnswers.length == questions.length;
            });
            saveProgress();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentQuestionIndex > 0)
              ElevatedButton.icon(
                onPressed: () {
                  // Fade out current content
                  _animationController?.reverse().then((_) {
                    setState(() {
                      currentQuestionIndex--;
                    });
                    // Fade in new content
                    _animationController?.forward();
                  });
                },
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: const Text('Sebelumnya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              )
            else
              const SizedBox(width: 120), // Placeholder for layout balance

            _buildQuestionNumberIndicator(),

            if (currentQuestionIndex < questions.length - 1)
              ElevatedButton.icon(
                onPressed: () {
                  // Fade out current content
                  _animationController?.reverse().then((_) {
                    setState(() {
                      currentQuestionIndex++;
                    });
                    // Fade in new content
                    _animationController?.forward();
                    saveProgress();
                  });
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                label: const Text('Selanjutnya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),

              )
            else if (canSubmit)
              ElevatedButton.icon(
                onPressed: _submitting ? null : submitAnswers,
                icon: _submitting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.check_circle_outline, size: 16),
                label: Text(_submitting ? 'Mengirim...' : 'Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionNumberIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${currentQuestionIndex + 1} / $totalQuestions',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'TWK':
        return Colors.blue;
      case 'TIU':
        return Colors.purple;
      case 'TKP':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _animationController?.dispose();
    _indicatorScrollController.dispose();
    super.dispose();
  }
}