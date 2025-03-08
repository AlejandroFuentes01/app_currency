import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoricalRatesChart extends StatelessWidget {
  final Map<String, double> ratesByDate;
  final List<String> timeLabels;
  final bool isLoading;
  final Color? lineColor;
  final Color? pointColor;

  const HistoricalRatesChart({
    Key? key,
    required this.ratesByDate,
    required this.timeLabels,
    this.isLoading = false,
    this.lineColor,
    this.pointColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;
    
    final chartLineColor = lineColor ?? colorScheme.primary;
    final chartPointColor = pointColor ?? colorScheme.primaryContainer;
    
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Cargando datos históricos...',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }
    
    if (ratesByDate.isEmpty || timeLabels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_outlined, size: 48, color: colorScheme.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar las divisas seleccionadas',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }
    
    // Encontrar valores mínimos y máximos para escalar el gráfico
    final values = ratesByDate.values.toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final closeValue = values.last; // El valor más reciente (de cierre)
    
    // Calcular un buen rango con margen para visualización
    double valueRange = maxValue - minValue;
    // Si el rango es muy pequeño, ampliarlo para mejor visualización
    if (valueRange < 0.001) valueRange = maxValue * 0.1;
    
    // Ampliar margen vertical para mejor visualización
    final adjustedMin = minValue - (valueRange * 0.15);
    final adjustedMax = maxValue + (valueRange * 0.15);
    final effectiveRange = adjustedMax - adjustedMin;
    
    // Generar el rango de fechas para mostrar (primero y último)
    String dateRange = '';
    if (timeLabels.isNotEmpty) {
      try {
        // Convertir las fechas de formato "DD/MM" a fechas completas
        final firstDateParts = timeLabels.first.split('/').map(int.parse).toList();
        final lastDateParts = timeLabels.last.split('/').map(int.parse).toList();
        
        // Asumimos que estamos en 2025 para el ejemplo
        final firstDate = DateTime(2025, firstDateParts[1], firstDateParts[0]);
        final lastDate = DateTime(2025, lastDateParts[1], lastDateParts[0]);
        
        // Formato: "1 mar 2025 - 7 mar 2025"
        final dateFormatter = DateFormat('d MMM yyyy', 'es_ES');
        dateRange = '${dateFormatter.format(firstDate)} - ${dateFormatter.format(lastDate)}';
      } catch (e) {
        // Si hay un error en el formato, simplemente mostraremos las etiquetas tal cual
        dateRange = '${timeLabels.first} - ${timeLabels.last}';
      }
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;
        
        // Espacio para etiquetas y leyenda
        final topPadding = 35.0; // Aumentado para la información de resumen
        final bottomPadding = 25.0;
        final leftPadding = 50.0;
        final rightPadding = 10.0;
        
        // Área útil para dibujar
        final plotWidth = chartWidth - leftPadding - rightPadding;
        final plotHeight = chartHeight - topPadding - bottomPadding;
        
        // Generar puntos para la línea
        final List<Offset> linePoints = [];
        
        // Calcular posiciones de los puntos
        for (int i = 0; i < timeLabels.length; i++) {
          final label = timeLabels[i];
          final value = ratesByDate[label] ?? 0;
          
          // Normalizar valor para altura (0 a 1)
          final normalizedHeight = (value - adjustedMin) / effectiveRange;
          
          // Calcular posición exacta para cada punto dentro del área útil
          final xPos = leftPadding + (i / (timeLabels.length - 1)) * plotWidth;
          final yPos = topPadding + plotHeight - (normalizedHeight * plotHeight);
          
          linePoints.add(Offset(xPos, yPos));
        }
        
        return Stack(
          children: [
            // Información de resumen en la parte superior
            Positioned(
              top: 5,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Text(
                      'cierre: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      closeValue.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mín: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      minValue.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'máx: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      maxValue.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Fondo limpio
            Container(
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? colorScheme.surfaceVariant.withOpacity(0.1)
                    : colorScheme.surfaceVariant.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            
            // Líneas de referencia horizontales
            ..._buildReferenceLines(
              chartHeight,
              chartWidth,
              adjustedMin,
              effectiveRange,
              colorScheme,
              topPadding,
              bottomPadding,
              leftPadding,
              plotHeight,
            ),
            
            // Líneas verticales sutiles (una por punto)
            ..._buildVerticalLines(
              linePoints,
              plotHeight,
              topPadding,
              colorScheme,
            ),
            
            // Área bajo la curva y la línea principal
            ClipRect(
              child: CustomPaint(
                size: Size(chartWidth, chartHeight),
                painter: LineChartPainter(
                  points: linePoints,
                  lineColor: chartLineColor,
                  pointColor: chartPointColor,
                  pointStrokeColor: isDarkMode ? Colors.black : Colors.white,
                  fillColor: chartLineColor.withOpacity(0.08),
                ),
              ),
            ),
            
            // Etiquetas de tiempo en el eje X
            Positioned(
              left: leftPadding,
              right: rightPadding,
              bottom: 5,
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  timeLabels.length,
                  (index) {
                    final isToday = index == timeLabels.length - 1;
                    return Container(
                      width: plotWidth / timeLabels.length,
                      alignment: Alignment.center,
                      child: Text(
                        timeLabels[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday 
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Construir líneas de referencia horizontales
  List<Widget> _buildReferenceLines(
    double height,
    double width,
    double minValue,
    double valueRange,
    ColorScheme colorScheme,
    double topPadding,
    double bottomPadding,
    double leftPadding,
    double plotHeight,
  ) {
    const int lineCount = 3; // Limitar a pocas líneas para un diseño minimalista
    final List<Widget> lines = [];
    
    for (int i = 0; i < lineCount; i++) {
      final double ratio = i / (lineCount - 1);
      final lineY = topPadding + plotHeight - (ratio * plotHeight);
      final value = minValue + (ratio * valueRange);
      
      // Línea horizontal
      lines.add(
        Positioned(
          top: lineY,
          left: leftPadding - 5,
          right: 0,
          child: Container(
            height: 1,
            color: colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
      );
      
      // Valor de referencia
      lines.add(
        Positioned(
          top: lineY - 6,
          left: 2,
          child: Container(
            width: leftPadding - 7,
            child: Text(
              value.toStringAsFixed(6),
              style: TextStyle(
                fontSize: 8,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      );
    }
    
    return lines;
  }
  
  // Construir líneas verticales sutiles para cada punto
  List<Widget> _buildVerticalLines(
    List<Offset> points,
    double plotHeight,
    double topPadding,
    ColorScheme colorScheme,
  ) {
    final List<Widget> lines = [];
    
    for (int i = 0; i < points.length; i++) {
      final xPos = points[i].dx;
      
      // Solo líneas sutiles, no para el primer y último punto
      if (i > 0 && i < points.length - 1) {
        lines.add(
          Positioned(
            left: xPos,
            top: topPadding,
            bottom: 20,
            child: Container(
              width: 0.5,
              color: colorScheme.onSurface.withOpacity(0.05),
            ),
          ),
        );
      }
    }
    
    return lines;
  }
}

// Pintor personalizado para el gráfico de líneas
class LineChartPainter extends CustomPainter {
  final List<Offset> points;
  final Color lineColor;
  final Color pointColor;
  final Color pointStrokeColor;
  final Color fillColor;
  final double lineWidth;
  final double pointRadius;
  
  LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.pointColor,
    required this.pointStrokeColor,
    required this.fillColor,
    this.lineWidth = 2.0,
    this.pointRadius = 3.5,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    
    // Pintura para la línea
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    
    // Pintura para el relleno bajo la línea
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    
    // Pintura para los puntos
    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    
    // Pintura para el borde de los puntos
    final pointStrokePaint = Paint()
      ..color = pointStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    
    // Crear el path para la línea
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    
    // Path para el área bajo la curva
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height - 25); // Ajustar por el margen inferior
    fillPath.lineTo(points.first.dx, points.first.dy);
    
    // Dibujar línea con curvas suaves
    if (points.length > 2) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        
        // Punto medio para curva suave
        final midPoint = Offset(
          (p1.dx + p2.dx) / 2,
          (p1.dy + p2.dy) / 2,
        );
        
        // Usar una curva cuadrática para suavizar la línea
        linePath.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
        fillPath.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
      }
      
      // Conectar al último punto
      linePath.lineTo(points.last.dx, points.last.dy);
      fillPath.lineTo(points.last.dx, points.last.dy);
    } else {
      // Si solo hay dos puntos, conectar directamente
      linePath.lineTo(points.last.dx, points.last.dy);
      fillPath.lineTo(points.last.dx, points.last.dy);
    }
    
    // Completar el path de relleno
    fillPath.lineTo(points.last.dx, size.height - 25); // Ajustar por el margen inferior
    fillPath.close();
    
    // Dibujar el relleno primero
    canvas.drawPath(fillPath, fillPaint);
    
    // Dibujar la línea principal
    canvas.drawPath(linePath, linePaint);
    
    // Dibujar puntos solo en posiciones clave
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Determinar el tamaño del punto según su posición
      double radius = pointRadius;
      if (i == 0 || i == points.length - 1) {
        radius = pointRadius * 1.2; // Primer y último punto ligeramente más grandes
      }
      
      // Punto principal
      canvas.drawCircle(point, radius, pointPaint);
      // Borde del punto
      canvas.drawCircle(point, radius, pointStrokePaint);
    }
  }
  
  @override
  bool shouldRepaint(LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.pointColor != pointColor ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.pointRadius != pointRadius;
}