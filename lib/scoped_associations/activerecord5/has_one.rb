module ScopedAssociations
  module ActiveRecord5
    module HasOne
      def valid_options(options)
        super + [:scoped]
      end

      def build(model, name, scope, options, &block)
        reflection = super(model, name, scope, options, &block)
        extend_reflection(reflection)
        reflection
      end

      def extend_reflection(reflection)
        if reflection.options[:scoped]
          reflection.extend ReflectionExtension
        end
      end

      class ScopedHasOneAssociation < ActiveRecord::Associations::HasOneAssociation
        def creation_attributes
          attributes = super
          attributes[reflection.foreign_scope] = reflection.name.to_s
          attributes
        end
      end

      module ReflectionExtension
        def foreign_scope
          if options[:as]
            "#{options[:as]}_scope"
          else
            name = active_record.name
            name.demodulize.underscore + "_scope"
          end
        end

        def scope
          old_scope = super
          scope_conditions = { foreign_scope => name }
          proc_scope = proc { where(scope_conditions) }
          if old_scope.nil?
            proc { instance_eval(&proc_scope) }
          else
            proc { instance_eval(&proc_scope).instance_eval(&old_scope) }
          end
        end

        def association_class
          ScopedHasOneAssociation
        end
      end
    end
  end
end

ActiveRecord::Associations::Builder::HasOne.send :extend, ScopedAssociations::ActiveRecord5::HasOne
