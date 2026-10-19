import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _ground = Color(0xFFF2F6F5);
const _sky = Color(0xFFDCEEFA);
const _garden = Color(0xFFE4F3DC);
const _blue = Color(0xFF1D4A87);
const _blueTint = Color(0xFFD9E6F7);
const _sun = Color(0xFFFFC94A);
const _sunTint = Color(0xFFFFF3CF);
const _lilac = Color(0xFFDCD3F8);
const _ink = Color(0xFF1E3A44);
const _muted = Color(0xFF3F5F6A);
const _turquoise = Color(0xFF168F9A);
const _turquoiseTint = Color(0xFFCDEBE8);

class RevenueModelScreen extends StatelessWidget {
  const RevenueModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      backgroundColor: _ground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Commercialization'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back · ආපසු',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(child: CustomPaint(painter: _MeadowPainter())),
          ),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, _) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 20, compact ? 16 : 28, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(compact ? 18 : 32, 50, compact ? 18 : 32, 30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: _blueTint, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Revenue Model',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: compact ? 28 : 34,
                                    fontWeight: FontWeight.w600,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 48,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _sun,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Monthly subscription fee · මාසික දායකත්ව ගාස්තුව',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _muted,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (compact)
                                  const Column(
                                    children: [
                                      _PackageCard(
                                        number: '1',
                                        title: 'Package 1: Individual · Free',
                                        sinhalaTitle: 'තනි දරුවෙකු · නොමිලේ',
                                        description: 'Basic version with ads',
                                        sinhalaDescription: 'දැන්වීම් සහිත මූලික පහසුකම්',
                                        price: 'Free · නොමිලේ',
                                      ),
                                      SizedBox(height: 18),
                                      _PackageCard(
                                        number: '2',
                                        title: 'Package 1: Individual · Premium',
                                        sinhalaTitle: 'තනි දරුවෙකු · වාරික',
                                        description: 'Full features, no ads',
                                        sinhalaDescription: 'සියලු පහසුකම්, දැන්වීම් නැත',
                                        price: 'LKR 1,000–2,000/month',
                                      ),
                                      SizedBox(height: 18),
                                      _PackageCard(
                                        number: '3',
                                        title: 'Package 2: Group',
                                        sinhalaTitle: 'දරුවන් කණ්ඩායමක් සඳහා',
                                        description: 'Multiple child profiles',
                                        sinhalaDescription: 'දරුවන් කිහිප දෙනෙකුගේ පැතිකඩ',
                                        price: 'LKR 10,000–25,000/month',
                                      ),
                                    ],
                                  )
                                else
                                  const IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _PackageCard(
                                            number: '1',
                                            title: 'Package 1: Individual · Free',
                                            sinhalaTitle: 'තනි දරුවෙකු · නොමිලේ',
                                            description: 'Basic version with ads',
                                            sinhalaDescription: 'දැන්වීම් සහිත මූලික පහසුකම්',
                                            price: 'Free · නොමිලේ',
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _PackageCard(
                                            number: '2',
                                            title: 'Package 1: Individual · Premium',
                                            sinhalaTitle: 'තනි දරුවෙකු · වාරික',
                                            description: 'Full features, no ads',
                                            sinhalaDescription: 'සියලු පහසුකම්, දැන්වීම් නැත',
                                            price: 'LKR 1,000–2,000/month',
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _PackageCard(
                                            number: '3',
                                            title: 'Package 2: Group',
                                            sinhalaTitle: 'දරුවන් කණ්ඩායමක් සඳහා',
                                            description: 'Multiple child profiles',
                                            sinhalaDescription: 'දරුවන් කිහිප දෙනෙකුගේ පැතිකඩ',
                                            price: 'LKR 10,000–25,000/month',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Choose the plan that suits your family · ඔබේ පවුලට ගැළපෙන සැලසුම තෝරන්න',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    color: _muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: _ground, width: 5),
                          ),
                          child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String number;
  final String title;
  final String sinhalaTitle;
  final String description;
  final String sinhalaDescription;
  final String price;

  const _PackageCard({
    required this.number,
    required this.title,
    required this.sinhalaTitle,
    required this.description,
    required this.sinhalaDescription,
    required this.price,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 240),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD58A), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _sunTint, shape: BoxShape.circle),
                  child: Text(number, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.w700, color: _blue)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.w600, color: _turquoise)),
                      const SizedBox(height: 2),
                      Text(sinhalaTitle, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 2, decoration: BoxDecoration(color: _turquoiseTint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 15),
            Text(description, style: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w800, color: _blue)),
            const SizedBox(height: 4),
            Text(sinhalaDescription, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: _muted, height: 1.35)),
            const SizedBox(height: 15),
            Container(height: 2, decoration: BoxDecoration(color: _turquoiseTint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text(price, style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: _blue)),
          ],
        ),
      );
}

class _MeadowPainter extends CustomPainter {
  const _MeadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Paint paint(Color color) => Paint()..color = color;
    canvas.drawRect(Offset.zero & size, paint(_ground));
    canvas.drawCircle(Offset(w * .92, h * .08), w * .45, paint(_sky));
    canvas.drawCircle(Offset(w * .92, h * .08), w * .28, paint(_blueTint.withValues(alpha: .8)));
    canvas.drawCircle(Offset(w * .06, h * .20), w * .18, paint(_sunTint));
    canvas.drawCircle(Offset(w * .13, h * .12), 22, paint(_sun));
    canvas.drawCircle(Offset(w * .78, h * .44), 13, paint(_lilac.withValues(alpha: .75)));

    Path hill(double start, double peak, double end) => Path()
      ..moveTo(0, h * start)
      ..quadraticBezierTo(w * .32, h * peak, w * .62, h * ((start + peak) / 2))
      ..quadraticBezierTo(w * .84, h * end, w, h * (end - .02))
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill(.82, .72, .84), paint(_lilac.withValues(alpha: .65)));
    canvas.drawPath(hill(.88, .78, .88), paint(_blueTint));
    canvas.drawPath(hill(.94, .86, .94), paint(_garden));
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter oldDelegate) => false;
}
