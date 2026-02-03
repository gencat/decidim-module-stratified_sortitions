# frozen_string_literal: true

require "spec_helper"
require "benchmark"

# Performance tests for the LEXIMIN algorithm
#
# These tests are excluded by default. Run with:
#   bundle exec rspec --tag performance
#
# Or run only performance tests:
#   bundle exec rspec spec/performance/
#
module Decidim
  module StratifiedSortitions
    describe "LEXIMIN Performance", :performance, type: :service do
      include LeximinHelpers

      before do
        require_cbc!
      end

      # Performance thresholds (in seconds)
      THRESHOLDS = {
        small: 5, # 50 participants, panel of 10
        medium: 15, # 200 participants, panel of 30
        large: 60, # 500 participants, panel of 50
        xlarge: 180, # 1000 participants, panel of 100
      }.freeze

      describe "small scale (50 participants, panel of 10)" do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 50,
            panel_size: 10,
            strata_config: simple_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "completes within #{THRESHOLDS[:small]} seconds" do
          time = Benchmark.realtime do
            result = FairSortitionService.new(sortition).call
            expect(result.success?).to be true
          end

          expect(time).to be < THRESHOLDS[:small],
                          "Small scale took #{time.round(2)}s, expected < #{THRESHOLDS[:small]}s"

          puts "  Small scale: #{time.round(3)}s"
        end
      end

      describe "medium scale (200 participants, panel of 30)" do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 200,
            panel_size: 30,
            strata_config: medium_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "completes within #{THRESHOLDS[:medium]} seconds" do
          time = Benchmark.realtime do
            result = FairSortitionService.new(sortition).call
            expect(result.success?).to be true
          end

          expect(time).to be < THRESHOLDS[:medium],
                          "Medium scale took #{time.round(2)}s, expected < #{THRESHOLDS[:medium]}s"

          puts "  Medium scale: #{time.round(3)}s"
        end
      end

      describe "large scale (500 participants, panel of 50)" do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 500,
            panel_size: 50,
            strata_config: complex_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "completes within #{THRESHOLDS[:large]} seconds" do
          time = Benchmark.realtime do
            result = FairSortitionService.new(sortition).call
            expect(result.success?).to be true
          end

          expect(time).to be < THRESHOLDS[:large],
                          "Large scale took #{time.round(2)}s, expected < #{THRESHOLDS[:large]}s"

          puts "  Large scale: #{time.round(3)}s"
        end
      end

      describe "extra large scale (1000 participants, panel of 100)", :slow do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 1000,
            panel_size: 100,
            strata_config: complex_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "completes within #{THRESHOLDS[:xlarge]} seconds" do
          time = Benchmark.realtime do
            result = FairSortitionService.new(sortition).call
            expect(result.success?).to be true
          end

          expect(time).to be < THRESHOLDS[:xlarge],
                          "XLarge scale took #{time.round(2)}s, expected < #{THRESHOLDS[:xlarge]}s"

          puts "  XLarge scale: #{time.round(3)}s"
        end
      end

      describe "component benchmarks" do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 100,
            panel_size: 20,
            strata_config: medium_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "reports time breakdown for each component" do
          constraint_time = Benchmark.realtime do
            Leximin::ConstraintBuilder.new(sortition)
          end

          builder = Leximin::ConstraintBuilder.new(sortition)

          feasibility_time = Benchmark.realtime do
            Leximin::FeasibilityChecker.new(builder).check
          end

          generator = Leximin::PanelGenerator.new(builder)
          panel_gen_time = Benchmark.realtime do
            generator.find_feasible_panel
          end

          panels = [generator.find_feasible_panel].compact
          solver = Leximin::DistributionSolver.new(builder)
          distribution_time = Benchmark.realtime do
            solver.compute(panels)
          end

          sampler = Leximin::PanelSampler.new([[1, 2, 3]], [1.0])
          sampling_time = Benchmark.realtime do
            1000.times { sampler.sample }
          end

          puts "\n  Component Breakdown (100 participants, panel of 20):"
          puts "    ConstraintBuilder:    #{(constraint_time * 1000).round(2)}ms"
          puts "    FeasibilityChecker:   #{(feasibility_time * 1000).round(2)}ms"
          puts "    PanelGenerator:       #{(panel_gen_time * 1000).round(2)}ms"
          puts "    DistributionSolver:   #{(distribution_time * 1000).round(2)}ms"
          puts "    PanelSampler (1000x): #{(sampling_time * 1000).round(2)}ms"

          # Sampling should be very fast
          expect(sampling_time / 1000).to be < 0.001, "Sampling too slow"
        end
      end

      describe "column generation iterations" do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 100,
            panel_size: 20,
            strata_config: medium_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "reports number of panels generated" do
          result = LeximinSelector.new(sortition).call

          puts "\n  Column Generation Stats:"
          puts "    Panels generated: #{result.panels.size}"
          puts "    Unique participants in panels: #{result.panels.flatten.uniq.size}"

          expect(result.panels.size).to be >= 1
          expect(result.panels.size).to be <= LeximinSelector::MAX_ITERATIONS
        end
      end

      describe "memory usage" do
        let(:sortition) do
          create_sortition_with_participants(
            num_participants: 200,
            panel_size: 30,
            strata_config: medium_strata_config,
            rspec_seed: @rspec_seed
          )
        end

        it "does not consume excessive memory" do
          # Get memory before
          memory_before = get_memory_usage

          result = FairSortitionService.new(sortition).call
          expect(result.success?).to be true

          # Force garbage collection
          GC.start

          memory_after = get_memory_usage
          memory_increase = memory_after - memory_before

          puts "\n  Memory Usage:"
          puts "    Before: #{(memory_before / 1024.0).round(2)} MB"
          puts "    After:  #{(memory_after / 1024.0).round(2)} MB"
          puts "    Increase: #{(memory_increase / 1024.0).round(2)} MB"

          # Should not increase by more than 100MB
          expect(memory_increase).to be < 100 * 1024,
                                     "Memory increase too high: #{(memory_increase / 1024.0).round(2)} MB"
        end
      end

      describe "scaling analysis" do
        it "reports performance across different scales" do
          puts "\n  Scaling Analysis:"
          puts "  #{"Participants".ljust(15)} #{"Panel".ljust(10)} #{"Time (s)".ljust(12)} #{"Panels".ljust(10)}"
          puts "  #{"-" * 47}"

          [
            { participants: 30, panel: 8 },
            { participants: 50, panel: 12 },
            { participants: 80, panel: 18 },
            { participants: 120, panel: 25 },
          ].each do |config|
            sortition = create_sortition_with_participants(
              num_participants: config[:participants],
              panel_size: config[:panel],
              strata_config: simple_strata_config,
              rspec_seed: @rspec_seed
            )

            result = nil
            time = Benchmark.realtime do
              result = FairSortitionService.new(sortition).call
            end

            puts "  #{config[:participants].to_s.ljust(15)} #{config[:panel].to_s.ljust(10)} #{time.round(3).to_s.ljust(12)} #{result.portfolio.num_panels}"

            # Clean up to save memory
            sortition.destroy!
          end
        end
      end

      private

      def simple_strata_config
        [
          {
            name: "Gender",
            substrata: [
              { name: "Male", percentage: 50 },
              { name: "Female", percentage: 50 },
            ],
          },
          {
            name: "Age",
            substrata: [
              { name: "Young", percentage: 50 },
              { name: "Senior", percentage: 50 },
            ],
          },
        ]
      end

      def medium_strata_config
        [
          {
            name: "Gender",
            substrata: [
              { name: "Male", percentage: 50 },
              { name: "Female", percentage: 50 },
            ],
          },
          {
            name: "Age",
            substrata: [
              { name: "18-30", percentage: 25 },
              { name: "31-45", percentage: 25 },
              { name: "46-60", percentage: 25 },
              { name: "61+", percentage: 25 },
            ],
          },
          {
            name: "Region",
            substrata: [
              { name: "North", percentage: 33 },
              { name: "Center", percentage: 34 },
              { name: "South", percentage: 33 },
            ],
          },
        ]
      end

      def complex_strata_config
        [
          {
            name: "Gender",
            substrata: [
              { name: "Male", percentage: 50 },
              { name: "Female", percentage: 50 },
            ],
          },
          {
            name: "Age",
            substrata: [
              { name: "18-25", percentage: 15 },
              { name: "26-35", percentage: 20 },
              { name: "36-45", percentage: 20 },
              { name: "46-55", percentage: 20 },
              { name: "56-65", percentage: 15 },
              { name: "66+", percentage: 10 },
            ],
          },
          {
            name: "Region",
            substrata: [
              { name: "North", percentage: 25 },
              { name: "East", percentage: 25 },
              { name: "South", percentage: 25 },
              { name: "West", percentage: 25 },
            ],
          },
          {
            name: "Education",
            substrata: [
              { name: "Basic", percentage: 30 },
              { name: "Secondary", percentage: 40 },
              { name: "University", percentage: 30 },
            ],
          },
        ]
      end

      def get_memory_usage
        # Get RSS memory in KB (Linux)
        if File.exist?("/proc/self/status")
          File.read("/proc/self/status").match(/VmRSS:\s+(\d+)/)[1].to_i
        else
          # Fallback for macOS
          `ps -o rss= -p #{Process.pid}`.to_i
        end
      end
    end
  end
end
