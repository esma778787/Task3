import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

const Color _infoPrimary = Color(0xFF6C5CE7);
const String _kHasSeenInformationScreen = 'has_seen_information_screen';

const List<List<Color>> cardGradients = [
  [Color(0xFF5B3FD3), Color(0xFF8B5CF6)],
  [Color(0xFF1565C0), Color(0xFF42A5F5)],
  [Color(0xFF00838F), Color(0xFF26C6DA)],
  [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  [Color(0xFFC2185B), Color(0xFFEC407A)],
  [Color(0xFFEF6C00), Color(0xFFFFA726)],
  [Color(0xFF3949AB), Color(0xFF7E57C2)],
  [Color(0xFF00796B), Color(0xFF26A69A)],
  [Color(0xFFF9A825), Color(0xFFFFC107)],
  [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
  [Color(0xFF0277BD), Color(0xFF29B6F6)],
  [Color(0xFFD84315), Color(0xFFFF7043)],
  [Color(0xFF558B2F), Color(0xFF8BC34A)],
  [Color(0xFF455A64), Color(0xFF78909C)],
];

class _InformationPageData {
  const _InformationPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.content,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget content;
}

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  int _currentCardIndex = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_currentCardIndex < _informationCards.length - 1) {
      setState(() {
        _currentCardIndex++;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: _infoPrimary,
        title: Text(
          'Bilgi Merkezi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Section
                    _buildHeroSection(),
                    const SizedBox(height: 24),

                    // Progress Indicator
                    _buildProgressSection(),
                    const SizedBox(height: 24),

                    // Information Card with Animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final slideAnimation = Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slideAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: _InformationPageCard(
                        key: ValueKey(_currentCardIndex),
                        data: _informationCards[_currentCardIndex],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Navigation Buttons
                    _buildNavigationButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B3FD3),
            Color(0xFF7C4DFF),
            Color(0xFF2186D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3FD3).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Avrupa Destekli Gençlik Fırsatlarını Keşfet',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Avrupa Dayanışma Programı, Gençlik Değişimleri ve Eğitim Kurslarını tanı; ilgi alanlarına ve yeteneklerine uygun fırsatları keşfet.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withAlpha(242),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Bu faaliyetler üniversite değişimi değildir. Akademik nottan çok motivasyon, öğrenme isteği, toplumsal katkı ve proje uyumu önemlidir.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withAlpha(230),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final currentColor =
        cardGradients[_currentCardIndex % cardGradients.length][0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bilgi Kartı ${_currentCardIndex + 1} / ${_informationCards.length}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: (_currentCardIndex + 1) / _informationCards.length,
            minHeight: 9,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(currentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(
              'Geri',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _currentCardIndex == 0 ? Colors.grey.shade300 : _infoPrimary,
              foregroundColor:
                  _currentCardIndex == 0 ? Colors.grey.shade600 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _currentCardIndex == 0 ? null : _previousCard,
          ),
          const SizedBox(width: 12),
          _currentCardIndex == _informationCards.length - 1
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(
                    'Uygulamaya Devam Et',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                )
              : ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    'İleri',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _infoPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _nextCard,
                ),
        ],
      ),
    );
  }
}

class _InformationPageCard extends StatelessWidget {
  final _InformationPageData data;

  const _InformationPageCard({required Key key, required this.data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = data.gradientColors[0];
    final backgroundColor = accentColor.withAlpha(20);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    data.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withAlpha(242),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Container(
              color: backgroundColor,
              padding: const EdgeInsets.all(24),
              child: data.content,
            ),
          ],
        ),
      ),
    );
  }
}

final List<_InformationPageData> _informationCards = [
  // Card 1
  _InformationPageData(
    title: 'Avrupa Destekli Gençlik Projeleri',
    subtitle:
        'Farklı ülkelerden gençleri öğrenme, gönüllülük ve toplumsal katkı amacıyla bir araya getiren Avrupa Birliği faaliyetleri.',
    icon: Icons.public_rounded,
    gradientColors: cardGradients[0],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Avrupa Birliği destekli gençlik projeleri, gençlerin başka ülkelerden katılımcılarla tanışmasını, farklı kültürleri deneyimlemesini ve toplumsal fayda sağlayan çalışmalara katılmasını amaçlar.\n\nBu projeler üniversite öğrenci değişimi veya akademik Erasmus programı değildir. Ders seçimi, sınav, bölüm veya akademik not ortalaması üzerine kurulmaz.\n\nFaaliyetler yaygın öğrenme yöntemlerini kullanır. Katılımcılar atölyeler, grup çalışmaları, gönüllülük görevleri, sosyal etkinlikler, kültürlerarası çalışmalar ve uygulamalı faaliyetler yoluyla öğrenir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('Uluslararası deneyim', cardGradients[0]),
            _buildInfoChip('Kültürlerarası öğrenme', cardGradients[0]),
            _buildInfoChip('Yeni arkadaşlıklar', cardGradients[0]),
            _buildInfoChip('Toplumsal katkı', cardGradients[0]),
            _buildInfoChip('Kişisel gelişim', cardGradients[0]),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Bu projelerde yalnızca ne bildiğin değil, ne öğrenmek istediğin ve projeye nasıl katkı sağlayabileceğin de önemlidir.',
          cardGradients[0],
        ),
      ],
    ),
  ),

  // Card 2
  _InformationPageData(
    title: 'Öğrenci Olmak veya GANO Gerekli mi?',
    subtitle:
        'Bu faaliyetlerin temel şartı üniversite öğrencisi veya yüksek akademik başarı sahibi olmak değildir.',
    icon: Icons.school_rounded,
    gradientColors: cardGradients[1],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ESC gönüllülük faaliyetleri, Erasmus+ Gençlik Değişimleri ve gençlik çalışanlarına yönelik Eğitim Kursları akademik Erasmus öğrenci hareketliliğinden farklıdır.\n\nBu projelerde genel olarak üniversite öğrencisi olma, belirli bir bölümde okuma veya belirli bir GANO\'ya sahip olma şartı bulunmaz.\n\nÖğrenci olmayan, mezun olan, çalışan, iş arayan veya gönüllülük faaliyetlerinde aktif olan gençler de uygun proje koşullarını sağladıkları sürece başvuru yapabilir.\n\nHer proje yaş, ikamet edilen ülke, tarih, katılımcı profili veya belirli bir beceri gibi kendi özel koşullarını belirleyebilir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Akademik başarı yerine motivasyon, proje uyumu, öğrenme isteği ve aktif katılım önemlidir.',
          cardGradients[1],
        ),
      ],
    ),
  ),

  // Card 3
  _InformationPageData(
    title: 'Katılımcılar Nasıl Seçilir?',
    subtitle:
        'Seçim sürecinde gencin motivasyonu, ilgi alanları ve projeye sağlayabileceği katkı değerlendirilir.',
    icon: Icons.people_rounded,
    gradientColors: cardGradients[2],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Katılımcılar yalnızca daha önce sahip oldukları sertifikalara veya deneyimlere göre seçilmez. Birçok proje, yeni şeyler öğrenmek isteyen ve proje faaliyetlerine aktif katılım gösterebilecek gençlere ulaşmayı hedefler.\n\nMotivasyon mektubunda projenin neden ilgini çektiğini, hangi becerilerini kullanabileceğini, hangi alanlarda gelişmek istediğini ve ekibe nasıl katkı sağlayabileceğini açıklaman önemlidir.\n\nBaşvuruna kopyalanmış ve genel ifadelerden oluşması yerine doğrudan proje temasına uygun, samimi ve kişisel olması beklenebilir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçim Kriterleri:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              'Gerçek ve anlaşılır motivasyon',
              'Proje konusuna ilgi',
              'Takım çalışmasına uyum',
              'Sorumluluk alabilme',
              'Öğrenmeye açıklık',
              'Kültürlerarası iletişime istekli olma',
              'Projeye sunulabilecek yetenekler',
            ]
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cardGradients[2][0],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ],
    ),
  ),

  // Card 4
  _InformationPageData(
    title: 'Katılım ve Karşılanan Masraflar',
    subtitle:
        'Seçilen katılımcıların temel proje giderleri Avrupa Birliği hibesi ve proje bütçesi kapsamında desteklenir.',
    icon: Icons.payment_rounded,
    gradientColors: cardGradients[3],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ESC gönüllülük faaliyetlerinde katılımcıdan program katılım ücreti alınmaz. Konaklama, yemek, proje yerine gidiş-dönüş seyahati, sigorta ve proje faaliyetleriyle ilgili temel giderler program kapsamında desteklenir.\n\nESC gönüllülerine kişisel ihtiyaçlarında kullanmaları için cep harçlığı da sağlanır. Projeye göre yerel ulaşım, dil desteği, eğitim, mentorluk ve vize gibi özel ihtiyaçlar için de destek sunulabilir.\n\nErasmus+ Gençlik Değişimleri ve Eğitim Kurslarında seyahat, konaklama, yemek ve faaliyet giderleri proje bütçesi kapsamında karşılanır.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('Konaklama', cardGradients[3]),
            _buildInfoChip('Yemek', cardGradients[3]),
            _buildInfoChip('Seyahat', cardGradients[3]),
            _buildInfoChip('Sigorta', cardGradients[3]),
            _buildInfoChip('Eğitim', cardGradients[3]),
            _buildInfoChip('Cep harçlığı', cardGradients[3]),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Seyahat desteği programın mesafe hesaplamasına ve proje bütçe sınırlarına göre uygulanır. Turistik geziler ve özel harcamalar katılımcıya ait olabilir.',
          cardGradients[3],
        ),
      ],
    ),
  ),

  // Card 5
  _InformationPageData(
    title: 'Avrupa Dayanışma Programı — ESC',
    subtitle:
        'Gençlerin topluma fayda sağlayan gönüllülük faaliyetlerine katılmasını destekleyen Avrupa Birliği programı.',
    icon: Icons.volunteer_activism_rounded,
    gradientColors: cardGradients[4],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ESC gönüllülüğü, gençlerin kendi ülkelerinde veya başka bir ülkede bir kuruluşun çalışmalarına gönüllü olarak katkı sağlamasına imkân verir.\n\nGönüllüler çevre, eğitim, kültür, sosyal içerme, gençlik çalışmaları, çocuklarla çalışma, medya, dijital beceriler veya yerel toplum gelişimi gibi alanlarda görev alabilir.\n\nGönüllülük yalnızca kuruluşa yardım etmek değildir. Katılımcı aynı zamanda yeni bir kültürü tanır, yabancı dil pratiği yapar, sorumluluk alır ve kişisel yeteneklerini geliştirir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kazanımlar:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              'Yabancı dil pratiği',
              'Bağımsız yaşama deneyimi',
              'Takım çalışması',
              'İletişim',
              'Problem çözme',
              'Mesleki deneyim',
            ]
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: cardGradients[4][0],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'ESC gönüllülük faaliyetleri genel olarak 18–30 yaş arasındaki gençlere yöneliktir.',
          cardGradients[4],
        ),
      ],
    ),
  ),

  // Card 6
  _InformationPageData(
    title: 'Kısa Süreli ESC Deneyimi',
    subtitle:
        'Daha kısa bir zaman içinde yoğun gönüllülük ve uluslararası ekip deneyimi yaşamak isteyen gençler için.',
    icon: Icons.timer_rounded,
    gradientColors: cardGradients[5],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kısa süreli ESC fırsatları çoğunlukla 2 hafta ile 2 ay arasında olabilir. Katılımcılar belirli bir proje hedefi için yoğun şekilde çalışır.\n\nBu faaliyetler ilk kez yurt dışına çıkacak, uzun süreli bir projeye hazır olup olmadığını görmek isteyen veya eğitim ve iş planları nedeniyle daha kısa süre ayırabilen gençler için uygun olabilir.\n\nKısa süreli olması projenin yalnızca gezi amacı taşıdığı anlamına gelmez. Katılımcıların proje görevlerine düzenli katılım göstermesi ve ekip içindeki sorumluluklarını yerine getirmesi beklenir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('Kısa ve yoğun', cardGradients[5]),
            _buildInfoChip('Uluslararası takım', cardGradients[5]),
            _buildInfoChip('Günlük görevler', cardGradients[5]),
            _buildInfoChip('Kültürel etkinlikler', cardGradients[5]),
          ],
        ),
      ],
    ),
  ),

  // Card 7
  _InformationPageData(
    title: 'Uzun Süreli ESC Deneyimi',
    subtitle:
        'Yeni bir ülkede daha uzun süre yaşayarak kapsamlı gönüllülük ve kişisel gelişim deneyimi kazanmak için.',
    icon: Icons.calendar_month_rounded,
    gradientColors: cardGradients[6],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Uzun süreli ESC faaliyetleri genellikle birkaç aydan 12 aya kadar devam edebilir. Gönüllü, ev sahibi kuruluşun günlük çalışmalarının düzenli bir parçası hâline gelir.\n\nUzun süreli faaliyetlerde katılımcı daha fazla sorumluluk alabilir, kendi küçük etkinliklerini geliştirebilir ve proje hedeflerine uzun vadeli katkı sağlayabilir.\n\nBu süreç yabancı dil gelişimi, farklı bir ülkede bağımsız yaşama, yeni bir sosyal çevre oluşturma ve gelecekteki eğitim veya kariyer planlarını değerlendirme açısından güçlü bir deneyim sağlayabilir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('Uzun süreli', cardGradients[6]),
            _buildInfoChip('Dil gelişimi', cardGradients[6]),
            _buildInfoChip('Bağımsız yaşam', cardGradients[6]),
            _buildInfoChip('Derin etki', cardGradients[6]),
          ],
        ),
      ],
    ),
  ),

  // Card 8
  _InformationPageData(
    title: 'ESC Gönüllülük Takımları',
    subtitle:
        'Farklı ülkelerden gençlerin ortak bir toplumsal hedef için ekip hâlinde çalıştığı gönüllülük faaliyetleri.',
    icon: Icons.groups_rounded,
    gradientColors: cardGradients[7],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gönüllülük takımları, farklı ülkelerden gençlerin kısa süreli ve yoğun bir çalışma programında bir araya geldiği ESC faaliyetleridir.\n\nKatılımcılar çevrenin korunması, kültürel miras, sosyal dayanışma, festival organizasyonu, gençlik çalışmaları veya yerel toplum faaliyetleri gibi ortak bir konu üzerinde çalışabilir.\n\nTakım projeleri iletişim, görev paylaşımı, liderlik, problem çözme ve farklı kültürlerden kişilerle birlikte çalışma becerilerini geliştirir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('2 hafta–2 ay', cardGradients[7]),
            _buildInfoChip('Ekip çalışması', cardGradients[7]),
            _buildInfoChip('Ortak hedef', cardGradients[7]),
            _buildInfoChip('Kültürel etkinlikler', cardGradients[7]),
          ],
        ),
      ],
    ),
  ),

  // Card 9
  _InformationPageData(
    title: 'Erasmus+ Gençlik Değişimleri',
    subtitle:
        'Farklı ülkelerden genç gruplarının ortak bir konu etrafında uygulamalı öğrenme faaliyetlerine katıldığı projeler.',
    icon: Icons.import_export_rounded,
    gradientColors: cardGradients[8],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gençlik Değişimleri üniversite veya okul değişimi değildir. Farklı ülkelerden gençler belirli bir proje konusu etrafında kısa süreli olarak bir araya gelir.\n\nFaaliyetlerde klasik ders ve sınav yerine yaygın öğrenme yöntemleri kullanılır. Katılımcılar bilgiyi yalnızca dinleyerek değil; uygulayarak, tartışarak, birlikte üreterek ve deneyim paylaşarak öğrenir.\n\nProjeler çevre, insan hakları, girişimcilik, dijital beceriler, kültür, sosyal içerme, sağlıklı yaşam veya demokratik katılım gibi konularda olabilir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faaliyet Örnekleri:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              'Atölyeler',
              'Grup çalışmaları',
              'Rol oyunları',
              'Tartışmalar',
              'Kültür geceleri',
              'Ortak ürün hazırlama',
            ]
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cardGradients[8][0],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'Gençlik Değişimleri genel olarak 13–30 yaş grubuna yöneliktir ve seyahat günleri hariç 5–21 gün sürer.',
          cardGradients[8],
        ),
      ],
    ),
  ),

  // Card 10
  _InformationPageData(
    title: 'Erasmus+ Eğitim Kursları',
    subtitle:
        'Gençlerle çalışan veya gönüllülük faaliyetlerinde aktif olan kişilerin yeni yöntemler ve beceriler kazanmasını sağlayan projeler.',
    icon: Icons.school_outlined,
    gradientColors: cardGradients[9],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Eğitim Kursları; gençlik çalışanları, aktif gönüllüler, eğitmenler, gençlik liderleri, dernek çalışanları ve gençlerle düzenli olarak çalışan kişiler için hazırlanabilir.\n\nBu faaliyetler akademik ders değildir. Uygulamalı eğitim, deneyim paylaşımı, yeni eğitim yöntemleri öğrenme, ortaklık geliştirme ve uluslararası ağ kurma üzerine kuruludur.\n\nBir eğitim kursunda katılımcılardan öğrendikleri yöntemleri kendi kuruluşlarında veya yerel çalışmalarında kullanmaları beklenebilir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('Eğitim kursu', cardGradients[9]),
            _buildInfoChip('Seminer', cardGradients[9]),
            _buildInfoChip('İşbaşı gözlem', cardGradients[9]),
            _buildInfoChip('Ağ kurma', cardGradients[9]),
          ],
        ),
      ],
    ),
  ),

  // Card 11
  _InformationPageData(
    title: 'Projeler Hangi Alanlarda Olabilir?',
    subtitle:
        'Proje konusu, toplumsal ihtiyaçlara ve ev sahibi kuruluşun çalışma alanına göre değişebilir.',
    icon: Icons.category_rounded,
    gradientColors: cardGradients[10],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gençlik projeleri yalnızca tek bir konuya odaklanmaz. Her proje farklı bir toplumsal ihtiyaca cevap verebilir ve katılımcıların farklı yeteneklerini kullanmasına imkân sağlayabilir.\n\nÖrneğin sosyal medya becerisi olan bir katılımcı kuruluşun dijital içeriklerine yardımcı olabilir. Sanatla ilgilenen biri çocuklarla yaratıcı atölyeler düzenleyebilir.\n\nBir alanda uzman olman zorunlu değildir. Projeler mevcut becerilerini kullanırken yeni beceriler geliştirmen için de fırsat sunar.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFieldChip('Eğitim', cardGradients[10]),
            _buildFieldChip('Çevre', cardGradients[10]),
            _buildFieldChip('Kültür', cardGradients[10]),
            _buildFieldChip('Gençlik', cardGradients[10]),
            _buildFieldChip('Çocuklar', cardGradients[10]),
            _buildFieldChip('Sosyal İçerme', cardGradients[10]),
            _buildFieldChip('Dijital', cardGradients[10]),
            _buildFieldChip('Medya', cardGradients[10]),
            _buildFieldChip('Sağlık', cardGradients[10]),
            _buildFieldChip('Spor', cardGradients[10]),
          ],
        ),
      ],
    ),
  ),

  // Card 12
  _InformationPageData(
    title: 'Hangi Proje Sana Uygun?',
    subtitle:
        'En uygun proje; ilgi alanlarına, geliştirmek istediğin becerilere ve proje ortamındaki beklentilerine göre değişir.',
    icon: Icons.check_circle_rounded,
    gradientColors: cardGradients[11],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bir projeyi yalnızca ülkesine veya süresine bakarak seçmek doğru olmayabilir. Projenin konusu, günlük görevleri, yaşam koşulları ve senden beklediği katkılar da değerlendirilmelidir.\n\nKendine hangi alanlarda çalışmaktan keyif aldığını, hangi becerilerini geliştirmek istediğini ve ekip içinde nasıl bir rol üstlenebileceğini sor.\n\nBaşvuruda projenin sana ne sağlayacağını açıklaman kadar, senin projeye ne sağlayabileceğini açıklaman da önemlidir.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kendini Değerlendirme:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              'Hangi toplumsal konular ilgini çekiyor?',
              'Hangi yeteneklerimi projede kullanabilirim?',
              'Hangi becerileri geliştirmek istiyorum?',
              'Farklı kültürlerden insanlarla yaşamaya hazır mıyım?',
            ]
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: cardGradients[11][0],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ],
    ),
  ),

  // Card 13
  _InformationPageData(
    title: 'Erasmus+ Simulation Sana Nasıl Yardımcı Olur?',
    subtitle:
        'Gerçek başvuru öncesinde proje seçimi, İngilizce, belge hazırlama ve karar verme alanlarında pratik yapmanı sağlar.',
    icon: Icons.lightbulb_rounded,
    gradientColors: cardGradients[12],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Erasmus+ Simulation, Avrupa destekli gençlik projelerine başvurmak isteyen kişilerin süreci deneyimleyerek öğrenmesini amaçlayan eğitim odaklı bir uygulamadır.\n\nUygulamada gerçek proje verilerini inceleyebilir, ilgi alanlarına uygun proje seçebilir, İngilizce seviyeni değerlendirebilir ve proje sırasında karşılaşabileceğin senaryolara cevap verebilirsin.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip('Proje keşfi', cardGradients[12]),
            _buildInfoChip('İngilizce test', cardGradients[12]),
            _buildInfoChip('Motivasyon yazısı', cardGradients[12]),
            _buildInfoChip('CV oluşturma', cardGradients[12]),
            _buildInfoChip('AI feedback', cardGradients[12]),
            _buildInfoChip('Puanlama', cardGradients[12]),
          ],
        ),
      ],
    ),
  ),

  // Card 14
  _InformationPageData(
    title: 'Önemli Bilgilendirme',
    subtitle:
        'Uygulama hazırlık amacı taşır; resmî proje koşulları her zaman ilgili kaynaklardan doğrulanmalıdır.',
    icon: Icons.warning_rounded,
    gradientColors: [
      const Color(0xFF1A237E),
      const Color(0xFF283593),
    ],
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bu uygulama eğitim amaçlı bir simülasyondur ve resmî bir Avrupa Birliği başvuru portalı değildir.\n\nProjelerin yaş, ülke, tarih, süre, görev, konaklama, seyahat desteği ve katılımcı profili koşulları birbirinden farklı olabilir.\n\nBaşvuru yapmadan önce proje ilanını tamamen oku. Kesin bilgileri Avrupa Gençlik Portalı, Türkiye Ulusal Ajansı veya projeyi yürüten kuruluşun resmî kanallarından doğrula.\n\nHiçbir kuruluşa yalnızca sosyal medya mesajı veya doğrulanmamış bağlantılar üzerinden kişisel bilgi ya da ödeme gönderme.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEF6C00),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_rounded,
                color: Color(0xFFEF6C00),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resmî kaynaklara daima güven',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
];

Widget _buildInfoChip(String label, List<Color> colors) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [colors[0].withAlpha(38), colors[1].withAlpha(25)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colors[0].withAlpha(77),
      ),
    ),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors[0],
      ),
    ),
  );
}

Widget _buildFieldChip(String label, List<Color> colors) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [colors[0].withAlpha(51), colors[1].withAlpha(25)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors[0],
      ),
    ),
  );
}

Widget _buildInfoBox(String text, List<Color> colors) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors[0].withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colors[0].withAlpha(51),
      ),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: colors[0].withAlpha(217),
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
