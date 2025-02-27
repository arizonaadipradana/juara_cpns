import 'package:flutter/material.dart';
import 'package:juara_cpns/class/platform_ui.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Terms & Conditions', 'FAQ', 'Contact'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PlatformUI.isWeb
          ? null
          : AppBar(
              title: const Text("Pusat Bantuan"),
              elevation: 0,
            ),
      body: ResponsiveBuilder(
        builder: (context, constraints, screenSize) {
          return screenSize.isDesktop
              ? _buildDesktopLayout(constraints)
              : _buildMobileLayout(constraints);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Left sidebar
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pusat Bantuan',
                    style: AppTheme.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildSidebarItem(
                  0, Icons.description_outlined, 'Terms & Conditions'),
              _buildSidebarItem(1, Icons.question_answer_outlined, 'FAQ'),
              _buildSidebarItem(2, Icons.contact_support_outlined, 'Contact'),
              const Spacer(),
              CustomButton(
                text: 'Kembali',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icons.arrow_back,
                isPrimary: true,
                disabled: false,
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tabs[_tabController.index],
                  style: AppTheme.textTheme.displaySmall,
                ),
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _getTabContent(_tabController.index),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            onTap: (index) {
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTermsAndConditionsTab(),
              _buildFAQTab(),
              _buildContactTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = index == _tabController.index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTabContent(int index) {
    switch (index) {
      case 0:
        return _buildTermsAndConditionsTab();
      case 1:
        return _buildFAQTab();
      case 2:
        return _buildContactTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTermsAndConditionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTermsSection(
            "1. CONDITIONS OF USE",
            "Juara CPNS is offered to you, the user, conditioned on your acceptance of the terms, "
                "conditions and notices contained or incorporated by reference herein and such additional terms "
                "and conditions, agreements, and notices that may apply to any page or section of the Site.",
          ),
          _buildTermsSection(
            "2. OVERVIEW",
            "Your use of this Site constitutes your agreement to all terms, conditions and notices. Please read "
                "them carefully. By using this Site, you agree to these Terms and Conditions, as well as any other "
                "terms, guidelines or rules that are applicable to any portion of this Site, without limitation or "
                "qualification. If you do not agree to these Terms and Conditions, you must exit the Site immediately "
                "and discontinue any use of information or products from this Site.",
          ),
          _buildTermsSection(
            "3. MODIFICATION OF THE SITE AND THESE TERMS & CONDITIONS",
            "Juara CPNS reserves the right to change, modify, alter, update or discontinue the terms, "
                "conditions, and notices under which this Site is offered and the links, content, information, prices "
                "and any other materials offered via this Site at any time and from time to time without notice or "
                "further obligation to you except as may be provided therein. We have the right to adjust prices from "
                "time to time. If for some reason there may have been a price mistake, Juara CPNS has the "
                "right to refuse the order. By your continued use of the Site following such modifications, alterations, "
                "or updates you agree to be bound by such modifications, alterations, or updates.",
          ),
          _buildTermsSection(
            "4. GRANT OF LICENSE",
            "Juara CPNS grants you the right to access and use the Licensed Software Platform solely for your "
                "internal business purposes for the duration of this Agreement. This right is non-exclusive, non-"
                "transferable, and limited by and subject to this Agreement. You may not: (a) modify, adapt, "
                "decompile, disassemble, or reverse engineer any component of the Licensed Software Platform; (b) "
                "create derivative works based on any component of the Licensed Software Platform; (c) allow any "
                "third party to use or have access to any component of the Licensed Software Platform or "
                "Documentation.",
          ),
          _buildTermsSection(
            "5. PROPRIETARY RIGHTS",
            "You acknowledge and agree that: (a) the Licensed Software Platform and Documentation are the "
                "property of Juara CPNS or its licensors and not Yours, and (b) You will use the Licensed Software "
                "Platform and Documentation only under the terms and conditions described herein.",
          ),
          _buildTermsSection(
            "6. FEES",
            "In consideration for the license granted, you shall pay to the Juara CPNS the license fee (the \"License "
                "Fee\") as set out in the fee schedule on the Pricing page of the Site. The License Fee is exclusive of "
                "VAT and shall be invoiced monthly and billed to the Licensee's credit card details. All such invoices "
                "shall be sent to the Licensee email address specified as part of the registration process. You shall "
                "pay all sales, use and excise taxes, and any other assessments in the nature of taxes however "
                "designated on the Licensed Software Platform or its license or use on or resulting from this "
                "Agreement, unless You furnish Juara CPNS with a certificate of exemption from payment of such taxes "
                "in a form reasonably acceptable to Juara CPNS.",
          ),
          _buildTermsSection(
            "7. ELIGIBILITY",
            "These Terms and Conditions cover either i) usage to evaluate the Licensed Software Platform, including "
                "via prototypes made available on Preview, or ii) usage by smaller independent developers, students, "
                "academic staff or hobbyists. All other uses are subject to a separate commercial agreement with Juara CPNS.",
          ),
          _buildTermsSection(
            "8. SUPPORT",
            "As a licensee of the Services you will receive 24x7 monitoring and dashboard reporting and you may contact Juara CPNS "
                "support by Whatsapp number.",
          ),
          _buildTermsSection(
            "9. TERMS OF TERMINATION",
            "Juara CPNS, at its sole discretion, may suspend or terminate this Agreement with immediate effect if: "
                "\n a. Juara CPNS suspects that you are endangering the License Software Platform; or "
                "\n b. You commit any material breach of your obligations under this Agreement; or "
                "\n c. You cease to carry on business or become unable to pay your debts; or"
                "\n d. You have or may become incapable of performing Your obligations under this Agreement."
                "\n Should this Agreement be terminated, you agree to return or certify to the desctruction of all copies of the Licensed Software "
                "Platform (including the SDKs) and Documentation, and all amounts owed by you under this Agreement shall be immediately due and payable.",
          ),
          _buildTermsSection(
            "10. CONFIDENTIALITY",
            "You may disclose COnfidential Information to your directors or employees or any members of your group "
                "that need to have access to it for the purpose of the Agreement; and/or professional advisers subject "
                "to appropriate conditions of confidentiality.",
          ),
          _buildTermsSection(
            "11. WARRANTY AND LIABILITY",
            "Juara CPNS warrants to and undertakes with You that: "
                "\n a. Juara CPNS will use its reasonable efforts to provide the Services and to exercise reasonable care and "
                "skill and in accordance with terms of this Agreement; and "
                "\n b. Juara CPNS has full right of power and authority to provide the Services to you in accordance with the terms of this Agreement.",
          ),
          _buildTermsSection(
            "12. YOUR OBLIGATIONS AND WARRANTIES",
            "You warrant to and undertake with Juara CPNS that you own the Intellectual Property Rights in the Licensee Content "
                "and are fully entitled to use the same for the purposes envisaged by this Agreement; "
                "\n a. the Licensee Content will not contain a virus, worm, Trojan, horse or other harmful code."
                "\n b. the Licensee Content will not breach any of the guidelines made available on the devices and related stores in which it will be released;"
                "\n c. the Licensee Content will not be unlawful, threatening, abusive, harmful, malicious, obscene, pornographic, profane, libellous, "
                "defamatory under the laws of any jurisdiction where the Apps and Web Apps can be accessed.",
          ),
          _buildTermsSection(
            "13. SECURITY",
            "Juara CPNS shall take all reasonable steps to prevent security breaches in its servers' interaction with you and security breaches "
                "in the interaction with resources or users outside of any firewall that may be built into the Juara CPNS' servers.",
          ),
          _buildTermsSection(
            "14. PRIVACY AND POLICY",
            "Your information is safe with us. Juara CPNS understands that privacy concerns are extremely important to our customers. "
                "You can rest assured that any information you submit to us will not be misused, abused or sold to any other parties. "
                "We only use your personal information to complete your order and for profile account",
          ),
          _buildTermsSection(
            "15. APPLICABLE LAWS",
            "These Terms and Conditions are governed by the law in force in Indonesia",
          ),
          _buildTermsSection(
            "16. QUESTIONS AND FEEDBACK",
            "We welcome your questions, comments, and concerns about privacy or any other information collected "
                "from you or about you. Please send us any and all feedback pertaining to privacy, or any other issue.",
          ),
          const SizedBox(height: 20),
          Center(
            child: Text("Legal Notice "
                "\n Juara CPNS is a brand by Juara Academy."
                "\n Copyright 2025 All Right Reserved."),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFAQItem(
            'Bagaimana cara mendaftar di Juara CPNS?',
            'Untuk mendaftar, Anda dapat mengklik tombol "Daftar" pada halaman utama, kemudian mengisi formulir pendaftaran dengan data pribadi Anda.',
          ),
          _buildFAQItem(
            'Apakah materi belajar di Juara CPNS diperbarui secara rutin?',
            'Ya, kami secara rutin memperbarui semua materi pembelajaran dan bank soal kami sesuai dengan perkembangan terbaru dari ketentuan CPNS.',
          ),
          _buildFAQItem(
            'Bagaimana cara melakukan pembayaran?',
            'Kami menerima pembayaran melalui transfer bank, e-wallet (GoPay, OVO, DANA), serta kartu kredit/debit. Petunjuk pembayaran akan muncul setelah Anda memilih paket yang ingin dibeli.',
          ),
          _buildFAQItem(
            'Apakah ada kebijakan pengembalian dana?',
            'Kami tidak menyediakan kebijakan pengembalian dana setelah pembelian dilakukan, tetapi Anda dapat mencoba fitur gratis kami sebelum membeli paket premium.',
          ),
          _buildFAQItem(
            'Berapa lama akses ke materi premium berlaku?',
            'Akses ke materi premium berlaku selama 1 tahun sejak tanggal pembelian. Setelah itu, Anda perlu memperpanjang langganan untuk terus mengakses materi premium.',
          ),
          _buildFAQItem(
            'Bagaimana jika saya lupa password akun saya?',
            'Anda dapat mengklik tombol "Lupa Password" pada halaman login, lalu ikuti petunjuk untuk mengatur ulang password Anda melalui email yang terdaftar.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return CustomCard(
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hubungi Kami',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Kami siap membantu Anda dengan pertanyaan seputar Juara CPNS. Silakan hubungi kami melalui salah satu saluran berikut:',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CustomCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.message,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'WhatsApp',
                        style: AppTheme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+62 896-9141-2345',
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: AppTheme.secondaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email',
                        style: AppTheme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'support@juara-cpns.web.app',
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension CustomCardExtension on CustomCard {
  CustomCard copyWith({EdgeInsetsGeometry? margin}) {
    return CustomCard(
      padding: padding,
      hasShadow: hasShadow,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: child,
    );
  }
}
