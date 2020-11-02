# typed: false

RSpec.describe("Api::MessageInput") do
  describe("#prepare") do
    it("can map to a Domain::Message when all values are present") do
      input =
        Api::MessageInput.new(
          nil,
          ruby_kwargs: {
            content: "Hello Joe",
            from_name: "Guillaume",
          },
          context: nil,
          defaults_used: Set.new,
        )

      message = input.prepare

      expect(message).to(be_kind_of(Domain::Message))
      expect(message.content).to(eq("Hello Joe"))
      expect(message.from_name).to(eq("Guillaume"))
    end

    it("can map to a Domain::Message with a nil from_name") do
      input =
        Api::MessageInput.new(
          nil,
          ruby_kwargs: {
            content: "Hello Joe",
            from_name: nil,
          },
          context: nil,
          defaults_used: Set.new,
        )

      message = input.prepare

      expect(message).to(be_kind_of(Domain::Message))
      expect(message.content).to(eq("Hello Joe"))
      expect(message.from_name).to(be_nil)
    end
  end
end

RSpec.describe("Api::Message") do
  describe("#from_name") do
    it("returns the message author's name") do
      message =
        Domain::Message.new(
          content: "Hello Joe",
          from_name: "Guillaume",
        )

      expect(Api::Message::Resolvers.from_name(message))
        .to(eq("Guillaume"))
    end

    it("can be nil") do
      message =
        Domain::Message.new(
          content: "Hello Joe",
          from_name: nil,
        )

      expect(Api::Message::Resolvers.from_name(message))
        .to(be_nil)
    end
  end

  describe("#content") do
    it("returns the message's content") do
      message =
        Domain::Message.new(
          content: "Hello Joe",
          from_name: "Guillaume",
        )

      expect(Api::Message::Resolvers.content(message))
        .to(eq("Hello Joe"))
    end
  end
end

RSpec.describe("Api::MutationRoot") do
  describe("#message_create") do
    it("calls Domain::Message with the message") do
      message =
        Domain::Message.new(
          content: "Hello Joe",
          from_name: "Guillaume",
        )

      expect(Domain::Message)
        .to(receive(:create).with(message).and_return(message))

      Api::MutationRoot::Resolvers
        .message_create(nil, nil, message_input: message)
    end
  end
end
