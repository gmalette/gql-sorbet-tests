# typed: true

require "sorbet-runtime"
require "graphql"
require_relative "sorbet/version"

module Domain; end
module Api; end

require_relative "graphql_api_delegation"

class Domain::Message
  extend(T::Sig)

  class Pending; end
  @buffer = T.let([], T::Array[Domain::Message])

  sig do
    params(message: Domain::Message)
      .returns(T.any(Domain::Message, Pending))
  end
  def self.create(message)
    if overwhelmed?
      @buffer.push(message)
      Pending.new
    else
      # omitted
      message
    end
  end

  sig { returns(T::Boolean) }
  def self.overwhelmed?
    false
  end

  sig do
    params(content: String, from_name: String)
      .void
  end
  def initialize(content:, from_name:)
    @content = content
    @from_name = from_name
  end

  sig { returns(String) }
  attr_reader(:content)

  sig { returns(String) }
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

  ObjectType = T.type_alias { Domain::Message }

  module Resolvers
    class << self
      extend(T::Sig)

      sig do
        params(object: ObjectType, _: BasicObject)
          .returns(String)
      end
      def content(object, *_)
        object.content
      end

      sig do
        params(object: ObjectType, _: BasicObject)
          .returns(T.nilable(String))
      end
      def from_name(object, *_)
        object.from_name
      end
    end
  end

  def content
    puts self.inspect
    "content"
  end

  delegate_to(Resolvers, methods: [:from_name])
end

class Api::MessagePending < GraphQL::Schema::Object
  using(Api::GraphQLDelegation)

  field(:_singleton_value, GraphQL::Types::Boolean, null: false)

  ObjectType = T.type_alias { Domain::Message::Pending }

  module Resolvers
    class << self
      extend(T::Sig)

      sig do
        params(object: ObjectType, _: BasicObject)
          .returns(T::Boolean)
      end
      def _singleton_value(object, *_)
        true
      end
    end
  end

  delegate_to(Resolvers, methods: [:_singleton_value])
end

class Api::MessageInput < GraphQL::Schema::InputObject
  extend(T::Sig)

  argument(:content, String, required: true)
  argument(:from_name, String, required: true)

  PrepareType = T.type_alias { Domain::Message }

  sig { returns(PrepareType) }
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

  sig { returns(String) }
  def from_name
    self[:from_name]
  end
end

class Api::MessageCreateResult < GraphQL::Schema::Union
  extend(T::Sig)

  possible_types(Api::Message, Api::MessagePending)

  ObjectType =
    T.type_alias do
      T.any(Api::Message::ObjectType, Api::MessagePending::ObjectType)
    end

  sig do
    params(object: ObjectType, _: BasicObject)
      .returns(T.any(
        [T.class_of(Api::Message), Api::Message::ObjectType],
        [T.class_of(Api::MessagePending), Api::MessagePending::ObjectType],
      ))
  end
  def self.resolve_type(object, *_)
    case object
    when Domain::Message
      [Api::Message, object]
    when Domain::Message::Pending
      [Api::MessagePending, object]
    else
      T.absurd(object)
    end
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
          message_input: Api::MessageInput::PrepareType,
        ).returns(Api::MessageCreateResult::ObjectType)
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
