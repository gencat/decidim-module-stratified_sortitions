# frozen_string_literal: true

require "spec_helper"

describe Decidim::StratifiedSortitions::AccessControl do
  User = Struct.new(:email, :admin) do
    def admin?
      admin
    end
  end

  after do
    described_class.reset_cache!
    ENV.delete("STRATIFIED_SORTITIONS_ALLOWED_EMAILS")
    ENV.delete("STRATIFIED_SORTITIONS_RESTRICTION_ENABLED")
  end

  describe ".allowed_emails" do
    it "normalizes and splits the env var" do
      ENV["STRATIFIED_SORTITIONS_ALLOWED_EMAILS"] = " Foo@Example.com, bar@example.com;baz@example.com "

      expect(described_class.allowed_emails).to eq(%w(foo@example.com bar@example.com baz@example.com))
    end
  end

  describe ".allowed_user?" do
    it "allows users when restriction is disabled by default" do
      ENV["STRATIFIED_SORTITIONS_ALLOWED_EMAILS"] = "foo@example.com"
      user = User.new("bar@example.com", false)

      expect(described_class.allowed_user?(user)).to be(true)
    end

    context "when restriction is enabled" do
      before do
        ENV["STRATIFIED_SORTITIONS_RESTRICTION_ENABLED"] = "true"
      end

      it "rejects admin users when not included in the allowlist" do
        ENV["STRATIFIED_SORTITIONS_ALLOWED_EMAILS"] = ""
        user = User.new("not-listed@example.com", true)

        expect(described_class.allowed_user?(user)).to be(false)
      end

      it "allows listed emails case-insensitively" do
        ENV["STRATIFIED_SORTITIONS_ALLOWED_EMAILS"] = "foo@example.com"
        user = User.new("Foo@Example.com", false)

        expect(described_class.allowed_user?(user)).to be(true)
      end

      it "rejects users not in the allowlist" do
        ENV["STRATIFIED_SORTITIONS_ALLOWED_EMAILS"] = "foo@example.com"
        user = User.new("bar@example.com", false)

        expect(described_class.allowed_user?(user)).to be(false)
      end
    end
  end
end
