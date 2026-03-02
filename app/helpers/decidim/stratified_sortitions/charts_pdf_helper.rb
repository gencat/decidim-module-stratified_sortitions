# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # View helpers used in the charts PDF template.
    # Generates inline SVG pie charts and HTML legends.
    module ChartsPdfHelper
      CHART_COLORS = %w(
        #3366CC #DC3912 #FF9900 #109618 #990099
        #0099C6 #DD4477 #66AA00 #B82E2E #316395
        #994499 #22AA99 #AAAA11 #6633CC #E67300
        #8B0707 #651067 #329262 #5574A6 #3B3EAC
      ).freeze

      # Generates an inline SVG pie chart from a data array of [label, value] pairs.
      def svg_pie_chart(data, size: 155)
        return "" if data.blank?

        total = data.sum { |_label, value| value.to_f }
        return "" if total.zero?

        cx = size / 2
        cy = size / 2
        r = (size / 2) - 4
        paths = []
        cumulative = 0.0

        data.each_with_index do |(_label, value), idx|
          slice = (value.to_f / total) * 360.0
          start_angle = cumulative
          end_angle = cumulative + slice
          cumulative = end_angle

          start_rad = (start_angle - 90) * Math::PI / 180.0
          end_rad = (end_angle - 90) * Math::PI / 180.0

          x1 = cx + (r * Math.cos(start_rad))
          y1 = cy + (r * Math.sin(start_rad))
          x2 = cx + (r * Math.cos(end_rad))
          y2 = cy + (r * Math.sin(end_rad))

          color = CHART_COLORS[idx % CHART_COLORS.size]
          large_arc = slice > 180 ? 1 : 0

          paths << if slice >= 359.99
                     %(<circle cx="#{cx}" cy="#{cy}" r="#{r}" fill="#{color}" stroke="white" stroke-width="1"/>)
                   else
                     %(<path d="M#{cx},#{cy} L#{x1.round(2)},#{y1.round(2)} A#{r},#{r} 0 #{large_arc},1 #{x2.round(2)},#{y2.round(2)} Z" fill="#{color}" stroke="white" stroke-width="1"/>)
                   end
        end

        %(<svg width="#{size}" height="#{size}" viewBox="0 0 #{size} #{size}" xmlns="http://www.w3.org/2000/svg">#{paths.join}</svg>).html_safe
      end

      # Generates an HTML legend block for the given chart data.
      def legend_html(data)
        return "" if data.blank?

        total = data.sum { |_label, value| value.to_f }

        items = data.each_with_index.map do |(label, value), idx|
          pct = total.positive? ? ((value.to_f / total) * 100).round(1) : 0.0
          color = CHART_COLORS[idx % CHART_COLORS.size]
          %(<div class="legend-item"><span class="legend-color" style="background:#{color}"></span>#{h(label)} (#{pct}%)</div>)
        end

        %(<div class="legend">#{items.join}</div>).html_safe
      end
    end
  end
end
