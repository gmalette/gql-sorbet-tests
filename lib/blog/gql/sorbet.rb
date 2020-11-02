# typed: true

require "sorbet-runtime"
require "graphql"
require_relative "sorbet/version"

module Domain; end
module Api; end

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

