# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # This mailer sends a notification email with the results of the import process.
      class ImportMailer < ApplicationMailer
        # Public: Sends a notification email with the result of an import process.
        #
        # user          - The user to be notified.
        # sample_import - The sample import record containing the import results.
        #
        # Returns nothing.
        def import(user, sample_import)
          @user = user
          @organization = user.organization
          @sample_import = sample_import

          with_user(user) do
            mail(to: "#{user.name} <#{user.email}>", subject: I18n.t("decidim.import_mailer.subject"))
          end
        end
      end
    end
  end
  end
