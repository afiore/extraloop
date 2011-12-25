require 'helpers/spec_helper'

describe Utils do
  describe "AugmentedHash" do
    describe "#get_in" do
      context "extending a hash object" do
        before do
          @hash = {
            :a => {
              :b => {
                :c => [
                  :x, :y, :z
                ]
              }
            }
          }.extend(Utils::DeepFetchable)
        end

        subject { @hash.get_in [:a, :b, :c, 2] }

        it { should eql(:z) }


        context "trying to fetch a key that does not exist" do
          subject { @hash.get_in [:a, :b, :wrong, :even_worst ]}

          it { should eql(nil)}
        end

      end

      context "extending an Array object" do
        before do
          @array = [1, 2, 3, 4, [5.1, 5.2, 5.3]].extend(Utils::DeepFetchable)
        end


        subject { @array.get_in [4, -1] }

        it { should eql(5.3) }
      end
    end
  end
end
