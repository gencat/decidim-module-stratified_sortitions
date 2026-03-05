# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe ChartsPdfHelper do
      # Create a minimal test host that includes the helper and Rails' h() method.
      let(:helper_host) do
        klass = Class.new do
          include ERB::Util
          include ActionView::Helpers::OutputSafetyHelper
          include ActionView::Helpers::TagHelper
          include Decidim::StratifiedSortitions::ChartsPdfHelper
        end
        klass.new
      end

      # -----------------------------------------------------------------------
      # svg_pie_chart
      # -----------------------------------------------------------------------
      describe "#svg_pie_chart" do
        context "when data is blank" do
          it "returns an empty string" do
            expect(helper_host.svg_pie_chart([])).to eq("")
            expect(helper_host.svg_pie_chart(nil)).to eq("")
          end
        end

        context "when all values are zero" do
          it "returns an empty string" do
            result = helper_host.svg_pie_chart([["A", 0], ["B", 0]])
            expect(result).to eq("")
          end
        end

        context "with valid data" do
          let(:data) { [["A", 60], ["B", 40]] }

          it "returns an HTML-safe string" do
            result = helper_host.svg_pie_chart(data)
            expect(result).to be_html_safe
          end

          it "returns an SVG element" do
            result = helper_host.svg_pie_chart(data)
            expect(result).to include("<svg")
            expect(result).to include("</svg>")
          end

          it "uses the default size of 155" do
            result = helper_host.svg_pie_chart(data)
            expect(result).to include('width="155"')
            expect(result).to include('height="155"')
          end

          it "respects a custom size" do
            result = helper_host.svg_pie_chart(data, size: 200)
            expect(result).to include('width="200"')
            expect(result).to include('height="200"')
          end

          it "sets the viewBox to match the size" do
            result = helper_host.svg_pie_chart(data, size: 155)
            expect(result).to include('viewBox="0 0 155 155"')
          end

          it "uses the first CHART_COLOR for the first slice" do
            result = helper_host.svg_pie_chart(data)
            expect(result).to include(ChartsPdfHelper::CHART_COLORS[0])
          end

          it "uses the second CHART_COLOR for the second slice" do
            result = helper_host.svg_pie_chart(data)
            expect(result).to include(ChartsPdfHelper::CHART_COLORS[1])
          end

          it "generates path elements for multiple slices" do
            result = helper_host.svg_pie_chart(data)
            expect(result).to include("<path")
          end
        end

        context "with a single-item slice (full circle)" do
          it "renders a circle element instead of a path" do
            result = helper_host.svg_pie_chart([["Only", 100]])
            expect(result).to include("<circle")
          end
        end

        context "with a slice just over 180 degrees (large arc flag)" do
          it "sets large_arc to 1 for slices > 180 degrees" do
            # 70% of 360 = 252 degrees → large arc
            result = helper_host.svg_pie_chart([["Big", 70], ["Small", 30]])
            # The big slice path should contain "1,1" (large-arc-flag=1, sweep=1)
            expect(result).to match(/A[\d.]+,[\d.]+ 0 1,1/)
          end

          it "sets large_arc to 0 for slices <= 180 degrees" do
            # 30% of 360 = 108 degrees → not a large arc
            result = helper_host.svg_pie_chart([["Big", 70], ["Small", 30]])
            # The small slice should contain "0,1"
            expect(result).to match(/A[\d.]+,[\d.]+ 0 0,1/)
          end
        end

        context "with more colors than CHART_COLORS" do
          it "wraps around the color palette" do
            many_slices = (1..25).map { |i| ["Item #{i}", 4] }
            expect { helper_host.svg_pie_chart(many_slices) }.not_to raise_error
          end
        end
      end

      # -----------------------------------------------------------------------
      # legend_html
      # -----------------------------------------------------------------------
      describe "#legend_html" do
        context "when data is blank" do
          it "returns an empty string" do
            expect(helper_host.legend_html([])).to eq("")
            expect(helper_host.legend_html(nil)).to eq("")
          end
        end

        context "with valid data" do
          let(:data) { [["Alpha", 75], ["Beta", 25]] }

          it "returns an HTML-safe string" do
            result = helper_host.legend_html(data)
            expect(result).to be_html_safe
          end

          it "wraps items in a .legend div" do
            result = helper_host.legend_html(data)
            expect(result).to include('class="legend"')
          end

          it "includes each label" do
            result = helper_host.legend_html(data)
            expect(result).to include("Alpha")
            expect(result).to include("Beta")
          end

          it "includes percentages" do
            result = helper_host.legend_html(data)
            expect(result).to include("75.0%")
            expect(result).to include("25.0%")
          end

          it "applies the first CHART_COLOR to the first item" do
            result = helper_host.legend_html(data)
            expect(result).to include("background:#{ChartsPdfHelper::CHART_COLORS[0]}")
          end

          it "applies the second CHART_COLOR to the second item" do
            result = helper_host.legend_html(data)
            expect(result).to include("background:#{ChartsPdfHelper::CHART_COLORS[1]}")
          end

          it "generates .legend-item elements" do
            result = helper_host.legend_html(data)
            expect(result.scan("legend-item").size).to eq(2)
          end
        end

        context "with a single item (100%)" do
          it "shows 100.0% percentage" do
            result = helper_host.legend_html([["Solo", 50]])
            expect(result).to include("100.0%")
          end
        end
      end

      # -----------------------------------------------------------------------
      # CHART_COLORS constant
      # -----------------------------------------------------------------------
      describe "CHART_COLORS" do
        it "has at least 10 colors" do
          expect(ChartsPdfHelper::CHART_COLORS.size).to be >= 10
        end

        it "contains valid hex color strings" do
          ChartsPdfHelper::CHART_COLORS.each do |color|
            expect(color).to match(/\A#[0-9A-Fa-f]{6}\z/)
          end
        end
      end
    end
  end
end
