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
