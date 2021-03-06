#because there may be multiple 'spec_helper' in load path when running from external test helper
require File.expand_path('../spec_helper.rb', __FILE__)

describe EY::ServicesAPI::Service do

  describe "#register_service" do

    describe "with a registration_url" do
      before do
        partner = @tresfiestas.partner
        @registration_url = partner[:registration_url]
        @registration_params = @tresfiestas.actor(:service_provider).registration_params
        @connection = EY::ServicesAPI.connection
      end

      it "can register a service" do
        service = @connection.register_service(@registration_url, @registration_params)
        service.should be_a EY::ServicesAPI::Service
        service.url.should_not be_nil
      end

      it "can list services" do
        services = @connection.list_services(@registration_url)
        services.class.should eq Array
      end

      it "can handle errors on registration" do
        lambda{ 
          @connection.register_service(@registration_url, @registration_params.merge(:name => nil))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Name can't be blank/)
      end

      describe "with a registered service" do
        before do
          @service = @connection.register_service(@registration_url, @registration_params)
        end

        it "can list services" do
          services = @connection.list_services(@registration_url)
          services.first.name.should eq @service.name
        end

        it "can fetch your service" do
          fetched_service = @connection.get_service(@service.url)
          fetched_service.description = fetched_service.description.gsub(/<[^>]*>/,"")
          fetched_service.should eq @service
        end

        it "can update your service" do
          new_name = "New and Improved: #{@service.name}"
          @service.update(:name => new_name)
          @service.name.should eq new_name
          fetched_service = @connection.get_service(@service.url)
          fetched_service.name.should eq new_name
        end

        it "can handle errors when updating your service" do
          old_name = @service.name
          lambda {
            @service.update(:name => nil)
          }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Name can't be blank/)
          @service.name.should eq old_name
          fetched_service = @connection.get_service(@service.url)
          fetched_service.name.should eq old_name
        end

        it "can delete your service" do
          @service.destroy
          lambda {
            @connection.get_service(@service.url)
          }.should raise_error EY::ServicesAPI::Connection::NotFound
        end

        it "can update and delete a service from the listing" do
          services = @connection.list_services(@registration_url)
          services.first.update(:name => "so brand new")
          services.first.destroy
        end

      end
    end
  end
end