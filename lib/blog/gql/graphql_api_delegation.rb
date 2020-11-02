# typed: false

# Unfortunately, Sorbet doesn't understand
# refinements for the moment, so this file
# has to be untyped. You'll also need to
# define a shim for `GraphQL::Schema::Object`,
# defining `delegate_to`.
module Api::GraphQLDelegation
  refine(GraphQL::Schema::Object.singleton_class) do
    def delegate_to(delegate, methods:)
      methods.each do |method_name|
        delegate_method = delegate.method(method_name)

        define_method(method_name) do |**args|
          if args.empty?
            delegate_method.call(object, context)
          else
            delegate_method.call(object, context, **args)
          end
        end
      end
    end
  end
end

