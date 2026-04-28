import os

filepath = r"c:\Users\puppa\OneDrive\Desktop\smart-travel\smart_travel_app\lib\screens\dashboard_screen.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to find the start of _buildMapCard() and replace everything from there.
start_str = "Widget _buildMapCard() {"
if start_str in content:
    idx = content.find(start_str)
    
    # We also have to keep the class closing brace `}` and the rest of the file if they are other public classes?
    # Let's find the closing brace of the `_DashboardScreenState` class.
    # It's better to just replace the body of _DashboardScreenState.
    
    # Actually, let's just use regular expressions, or we can just cut from `_buildMapCard` to the end of the file,
    # and append a `}` to close the `_DashboardScreenState` class, and we drop `_Bar`, `_AgentChip` and `_MapPainter`.
    
    new_methods = """
  Widget _buildBody() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              // 1. Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAB9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.book, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Voyager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF008080),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none_rounded, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 24),
              
              // 2. Greeting
              Row(
                children: [
                  Text(
                    'Hello, $_greetingName ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
              const Text(
                'Your travel assistant',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
              // 3. Live Map Card
              _buildStitchMapCard(),
              const SizedBox(height: 24),

              // 4. Today's Journey
              _buildSectionHeader('Today\\'s Journey', action: 'TIMELINE'),
              const SizedBox(height: 16),
              _buildStitchJourney(),
              const SizedBox(height: 24),

              // 5. Expense Warning Card
              _buildStitchExpenseWarning(),
              const SizedBox(height: 24),

              // 6. Auto Detected Expenses
              _buildStitchAutoExpenses(),
              const SizedBox(height: 24),

              // 7. Upcoming Trips
              _buildSectionHeader('Upcoming Trips'),
              const SizedBox(height: 16),
              _buildStitchUpcomingTrips(),
              const SizedBox(height: 24),

              // 8. Recent Memories
              _buildSectionHeader('Recent Memories'),
              const SizedBox(height: 16),
              _buildStitchMemories(),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openTripSearch,
            backgroundColor: const Color(0xFF008080),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildStitchMapCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF8BAE90),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEBEAD7),
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/header.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008080),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE NOW',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are traveling in ${travelData.cityName.isEmpty ? 'Hyderabad' : travelData.cityName}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.near_me, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          travelData.places.isNotEmpty ? travelData.places.first.name : 'Banjara Hills, Road No. 12',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStitchJourney() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _journeyStitchItem('Cafe', Icons.local_cafe, '09:30 AM', const Color(0xFFD4E5F9), const Color(0xFF4C8DDF)),
          _journeyStitchItem('Mall', Icons.shopping_bag, '12:45 PM', const Color(0xFFD3EBE8), const Color(0xFF008080)),
          _journeyStitchItem('Park', Icons.park, '04:20 PM', const Color(0xFFFDECD4), const Color(0xFFDF7B4C)),
        ],
      ),
    );
  }

  Widget _journeyStitchItem(String title, IconData icon, String time, Color bgColor, Color iconColor) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF102A43))),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildStitchExpenseWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF008080),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF008080).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pie_chart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You are spending more on food this week',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try budget-friendly options nearby. We\\'ve found 3 local spots with high ratings.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchAutoExpenses() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Auto Detected\\nExpenses',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF102A43), height: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('DETECTED FROM GMAIL', style: TextStyle(color: Color(0xFF4C8DDF), fontSize: 8, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _expenseStitchItem('Swiggy', 'Today, 2:15 PM', '₹500', Icons.fastfood, const Color(0xFFF1F3F5)),
          const SizedBox(height: 16),
          _expenseStitchItem('Uber ride', 'Yesterday', '₹300', Icons.directions_car, const Color(0xFFF1F3F5)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: const Text('View All Expenses', style: TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _expenseStitchItem(String title, String subtitle, String amt, IconData icon, Color bgColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF355264), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF102A43))),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Colors.blueGrey)),
            ],
          ),
        ),
        Text(amt, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF102A43))),
      ],
    );
  }

  Widget _buildStitchUpcomingTrips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tripStitchCard('Goa Trip', 'Nov 12 - Nov 16', const Color(0xFFD9832B)),
          _tripStitchCard('Hyderabad', 'Dec 02 - Dec 06', const Color(0xFF2B78D9)),
        ],
      ),
    );
  }

  Widget _tripStitchCard(String title, String dates, Color tagColor) {
    return Container(
      width: 220,
      height: 120,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/header.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(dates, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchMemories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _memoryStitchCard(const Color(0xFF8BAE90)),
          _memoryStitchCard(const Color(0xFFB1C9CD)),
          _memoryStitchCard(const Color(0xFFE2C992)),
          _memoryStitchCard(const Color(0xFF637C90)),
        ],
      ),
    );
  }

  Widget _memoryStitchCard(Color color) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/header.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
        ),
      ),
    );
  }
}
"""
    
    new_content = content[:idx] + new_methods
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("PATCH APPLIED SUCCESSFULLY")
else:
    print("START STRING NOT FOUND")
