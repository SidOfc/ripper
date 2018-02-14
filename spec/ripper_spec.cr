require "./spec_helper"

INPUT  = File.read File.join(__DIR__, "files", "input.rip")
OUTPUT = File.read File.join(__DIR__, "files", "output.css")

describe Ripper do
  describe "Selectors" do
    it "can parse a simple selector" do
      Ripper.parse(INPUT).should eq OUTPUT
    end
  end
end
