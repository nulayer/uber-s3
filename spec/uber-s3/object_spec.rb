require '../spec_helper'

describe UberS3::Object do
  [:net_http, :em_http_fibered].each do |connection_adapter|
  # [:net_http].each do |connection_adapter|

    context "#{connection_adapter}: Object" do
      let(:s3) do
        UberS3.new({
          :access_key         => SETTINGS['access_key'],
          :secret_access_key  => SETTINGS['secret_access_key'],
          :bucket             => SETTINGS['bucket'],
          :persistent         => SETTINGS['persistent'],
          :adapter            => connection_adapter
        })
      end

      let(:obj) { UberS3::Object.new(s3.bucket, '/test.txt', 'heyo') }
      
      it 'storing and loading an object' do
        spec(s3) do
          obj.save.should == true
          obj.exists?.should == true
      
          #--
      
          key = 'test.txt'
          value = 'testing 1234...'
          
          s3.store(key, value).should == true
      
          s3.exists?(key).should == true
          s3.object(key).exists?.should == true
          s3.exists?('asdfasdfasdf').should == false
      
          s3[key].value.should == value
      
          s3[key].delete.should == true
          s3[key].exists?.should == false
        end
      end
      
      it 'storing and loading an object with meta' do
        spec(s3) do
          obj.set_meta('a','a')
          obj.set_meta('z','z')
          obj.set_meta('test',"this is a test of meta")
          obj.save.should == true
          obj.exists?.should == true
      
          #--
      
          key = 'test2.txt'
          value = 'testing 1234...'
          meta = {}
          meta['a'] = 'a'
          meta['z'] = 'z'
          meta['test'] = "this is a test of meta"
          
          s3.store(key, value, :meta => meta).should == true
      
          s3.exists?(key).should == true
          s3.object(key).exists?.should == true
          s3.exists?('asdfasdfasdf').should == false
      
          s3[key].value.should == value
          s3[key].meta['a'].should == 'a'
          s3[key].meta['z'].should == 'z'
          s3[key].meta['test'].should == "this is a test of meta"
      
          s3[key].delete.should == true
          s3[key].exists?.should == false
        end
      end
      
      it 'has access level control' do
        spec(s3) do
          obj.access = :public_read
          obj.save.should == true
        end
      end
      
      it 'perform md5 integrity check' do
        spec(s3) do
          obj.content_md5 = Digest::MD5.hexdigest(obj.value)          
          obj.save.should == true
        end
      end

      it 'encode the data with gzip' do
        spec(s3) do        
          key = 'gzip_test.txt'
          value = 'testing 1234...'*256
        
          s3.store(key, value, { :gzip => true })
        
          # Uber S3 client will auto-decode ...
          gzipped_data = s3[key].value
          gzipped_data.bytesize.should == value.bytesize
          
          # But, let's make sure on the server it's the small size
          header = s3.connection.head(key).header
          content_length = [header['content-length']].flatten.first.to_i
          content_length.should < value.bytesize
        end
      end

      it 'keep persistent connection with many objects saved' do
        # NOTE: currently this doesn't actually confirm we've kept
        # a persistent connection open.. just helps with empirical testing
        spec(s3) do
          dummy_data = "A"*1024

          25.times do
            rand_key = (0...8).map{65.+(rand(25)).chr}.join
            s3.store(rand_key, dummy_data)
            # puts "Storing #{rand_key}"
          end

        end
      end
      
    end
    
  end
end
