import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dorotea_app/models/humor_event.dart';
import 'package:dorotea_app/humor_data_generator.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart'; // Importe a tela de Perfil
import 'package:dorotea_app/Telas_X/about_screen.dart'; // Importe a tela Sobre
import 'package:dorotea_app/Telas_X/home_screen.dart'; // Importe a tela Home

class ReportScreen extends StatefulWidget {
  final String userEmail;
  const ReportScreen({super.key, required this.userEmail});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late List<HumorEvent> _humorData;
  late List<HumorEvent> _filteredData;
  String _selectedTimeframe = 'Semana';
  int _selectedIndex = 0; // Adicione esta variável

  @override
  void initState() {
    super.initState();
    _humorData = generateSimulatedData();
    _filterData(_selectedTimeframe);
  }

  // --- Adicione esta lógica de navegação ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(email: widget.userEmail)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userEmail: widget.userEmail),
          ),
        );
        break;
    }
  }
  // --- Fim da lógica de navegação ---

  void _filterData(String timeframe) {
    setState(() {
      _selectedTimeframe = timeframe;
      final now = DateTime.now();
      _filteredData = _humorData.where((event) {
        if (timeframe == 'Dia') {
          return now.difference(event.dataHora).inHours <= 24;
        } else if (timeframe == 'Semana') {
          return now.difference(event.dataHora).inDays <= 7;
        } else {
          return now.difference(event.dataHora).inDays <= 30;
        }
      }).toList();
      
      // Ordena os dados para que o gráfico seja desenhado corretamente
      _filteredData.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    });
  }

  IconData _getHumorIcon(int humorValue) {
    switch (humorValue) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: Text(
          'DoroTEA',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gráfico de Humor',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Dia', 'Semana', 'Mês'].map((timeframe) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton(
                              onPressed: () => _filterData(timeframe),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedTimeframe == timeframe
                                    ? primaryPurple.withAlpha(204)
                                    : Colors.grey[200],
                                foregroundColor: _selectedTimeframe == timeframe ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(timeframe),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (_filteredData.length - 1).toDouble(),
                          minY: 1,
                          maxY: 5,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 1,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return const FlLine(color: Color(0xffececec), strokeWidth: 1);
                            },
                            getDrawingVerticalLine: (value) {
                              return const FlLine(color: Color(0xffececec), strokeWidth: 1);
                            },
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= _filteredData.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final event = _filteredData[index];
                                  String format;
                                  // Adiciona uma lógica para ajustar o formato da data
                                  if (_selectedTimeframe == 'Dia') {
                                    format = 'HH:mm'; // Ex: 14:30
                                  } else if (_selectedTimeframe == 'Semana') {
                                    format = 'EE'; // Ex: Seg, Ter, Qua
                                  } else { // Mês
                                    format = 'dd/MM'; // Ex: 25/10
                                  }
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Text(
                                      DateFormat(format, 'pt_BR').format(event.dataHora),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                                // Ajusta o intervalo para que os rótulos não se sobreponham
                                interval: _filteredData.length > 7 ? 2 : 1,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < 1 || value.toInt() > 5) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getHumorIcon(value.toInt()), size: 16, color: Colors.grey[700]),
                                        const SizedBox(width: 4),
                                        Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 77, 76, 76))),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _filteredData.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value.humor.toDouble());
                              }).toList(),
                              isCurved: true,
                              color: primaryPurple.withAlpha(204),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: primaryPurple,
                                    strokeColor: Colors.white,
                                    strokeWidth: 2,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: primaryPurple.withAlpha(76),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Relatórios Detalhados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            
            _filteredData.isEmpty
                ? const Center(child: Text('Nenhum dado encontrado para o período.', style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final event = _filteredData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(event.dataHora)}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Música: ${event.musica}'),
                              Text('Duração: ${event.duracao}'),
                              Text('Mudança de Humor: ${event.mudancaHumor}'),
                              Row(
                                children: [
                                  const Text('Humor: '),
                                  Icon(_getHumorIcon(event.humor), color: primaryPurple),
                                  Text(' (${event.humor})'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'DoroTEA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
