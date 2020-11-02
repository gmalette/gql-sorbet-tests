# typed: true

require "sorbet-runtime"
require "graphql"
require_relative "sorbet/version"

module Domain; end
module Api; end

require_relative "graphql_api_delegation"

class Domain::Message
  extend(T::Sig)

  sig do
    params(message: Domain::Message)
      .returns(Domain::Message)
  end
  def self.create(message)
    # omitted
    message
  end

  # Messages will be anonymous if from_name == nil
  sig do
    params(content: String, from_name: T.nilable(String))
      .void
  end
  def initialize(content:, from_name:)
    @content = content
    @from_name = from_name
  end

  sig { returns(String) }
  attr_reader(:content)

  sig { returns(T.nilable(String)) }
  attr_reader(:from_name)
end

# For this example, we'll be using mostly
# the `MutationRoot`, but the graphql-ruby
# gem requires a valid `QueryRoot`, so we'll
# provide it with a dummy one.
class Api::QueryRoot < GraphQL::Schema::Object
  field(:version, Integer, null: false)
end

class Api::Message < GraphQL::Schema::Object
  using(Api::GraphQLDelegation)

  field(:content, String, null: false)
  field(:from_name, String, null: true)

  module Resolvers
    class << self
      extend(T::Sig)

      sig do
        params(object: Domain::Message, _: BasicObject)
          .returns(String)
      end
      def content(object, *_)
        object.content
      end

      sig do
        params(object: Domain::Message, _: BasicObject)
          .returns(T.nilable(String))
      end
      def from_name(object, *_)
        object.from_name
      end
    end
  end

  delegate_to(Resolvers, methods: [:content, :from_name])
end

class Api::MessageInput < GraphQL::Schema::InputObject
  extend(T::Sig)

  argument(:content, String, required: true)
  argument(:from_name, String, required: false)

  sig { returns(Domain::Message) }
  def prepare
    Domain::Message.new(
      content: content,
      from_name: from_name,
    )
  end

  private

  sig { returns(String) }
  def content
    self[:content]
  end

  sig { returns(T.nilable(String)) }
  def from_name
    self[:from_name]
  end
end

class Api::MutationRoot < GraphQL::Schema::Object
  extend(T::Sig)
  using(Api::GraphQLDelegation)

  field(:message_create, Api::Message, null: false) do |f|
    f.argument(:message_input, Api::MessageInput, required: true)
  end

  module Resolvers
    class << self
      extend(T::Sig)

      sig do
        params(
          _obj: BasicObject,
          _context: BasicObject,
          message_input: Domain::Message,
        ).returns(Domain::Message)
      end
      def message_create(_obj, _context, message_input:)
        Domain::Message.create(message_input)
      end
    end
  end

  delegate_to(Resolvers, methods: [:message_create])
end

class Api::Schema < GraphQL::Schema
  query(Api::QueryRoot)
  mutation(Api::MutationRoot)
end
