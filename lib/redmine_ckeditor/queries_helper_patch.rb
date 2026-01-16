module RedmineCkeditor
  module QueriesHelperPatch

    def self.included(receiver)
      receiver.send(:include, InstanceMethods)
      receiver.class_eval do
        alias_method :csv_value_without_redmine_ckeditor, :csv_value
        alias_method :csv_value, :csv_value_with_redmine_ckeditor
      end
    end

    module InstanceMethods
      # Retrieve query updated for project templates, where only template issues should be displayed
      def csv_value_with_redmine_ckeditor(column, issue, value)
        result_value = csv_value_without_redmine_ckeditor(column, issue, value)

        if RedmineCkeditor.enabled? && value.class == String
          result_value = Nokogiri::HTML(result_value).text
          if params[:encoding]
            result_value = Redmine::CodesetUtil.from_utf8(result_value, params[:encoding])
          end
        end

        result_value
      end

    end
  end



end
