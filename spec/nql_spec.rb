lib_dir = File.expand_path("../lib", File.dirname(__FILE__))
$LOAD_PATH.unshift(lib_dir) if File.directory?(lib_dir) && !$LOAD_PATH.include?(lib_dir)

require 'nagix'
require 'yaml'

describe Nagix::NQL do
	let(:nql) { Nagix::NQL.new }

	describe "SELECT * FROM x" do
	  it "creates a GET query for x with no filter" do
      query = nql.parse("SELECT * FROM x")
	    query.should eq("GET x\nResponseHeader: fixed16\n")
	  end
	end

	describe "SELECT a, b FROM x" do
	  it "creates a GET query for columns a and b from x with no filter" do
      query = nql.parse("SELECT a,b FROM x")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\n")
	  end
	end

	describe "SELECT * FROM x WHERE a = 'foo'" do
	  it "creates a GET query for x with a single filter for a = foo" do
      query = nql.parse("SELECT * FROM x WHERE a = 'foo'")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a = foo\n")
	  end
	end

	describe "SELECT a, b FROM x WHERE a = 'foo'" do
	  it "creates a GET query for columns a and b from x with a single filter for a = foo" do
      query = nql.parse("SELECT a,b FROM x WHERE a = 'foo'")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\nFilter: a = foo\n")
	  end
	end

	describe "SELECT a, b FROM x WHERE a = 'foo'" do
	  it "creates a GET query for columns a and b from x with a single filter for a = foo" do
      query = nql.parse("SELECT a,b FROM x WHERE a = 'foo'")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\nFilter: a = foo\n")
	  end
	end

	describe "SELECT * FROM x WHERE a != 'foo'" do
	  it "creates a GET query for all columns * from x with a single filter for a != foo" do
      query = nql.parse("SELECT * FROM x WHERE a != 'foo'")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a != foo\n")
	  end
	end

	describe "SELECT a, b FROM x WHERE a > 2" do
	  it "creates a GET query for columns a and b from x with a single filter for a > 2" do
      query = nql.parse("SELECT a,b FROM x WHERE a > 2")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\nFilter: a > 2\n")
	  end
	end

	describe "SELECT * FROM x WHERE a >= 2.0" do
	  it "creates a GET query for all columns from x with a single filter for a >= 2.0" do
      query = nql.parse("SELECT * FROM x WHERE a >= 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a >= 2.0\n")
	  end
	end

	describe "SELECT a, b FROM x WHERE a < 2e3" do
	  it "creates a GET query for columns a and b from x with a single filter for a < 2e3" do
      query = nql.parse("SELECT a,b FROM x WHERE a < 2e3")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\nFilter: a < 2000.0\n")
	  end
	end

	describe "SELECT * FROM x WHERE a <= 'foo'" do
	  it "creates a GET query for all columns from x with a single filter for a <= 'foo'" do
      query = nql.parse("SELECT * FROM x WHERE a <= 'foo'")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a <= foo\n")
	  end
	end

	describe "SELECT a, b FROM x WHERE a < 'foo' AND b > 2.0" do
	  it "creates a GET query for columns a and b from x with two filters for a < 'foo' and b > 2.0" do
      query = nql.parse("SELECT a,b FROM x WHERE a < 'foo' AND b > 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\nFilter: a < foo\nFilter: b > 2.0\nAnd: 2\n")
	  end
	end

	describe "SELECT * FROM x WHERE a >= 2 OR b != 'foo'" do
	  it "creates a GET query for all columns from x with a single filter for a >= 2 or b != 'foo'" do
      query = nql.parse("SELECT * FROM x WHERE a >= 2 OR b != 'foo'")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a >= 2\nFilter: b != foo\nOr: 2\n")
	  end
	end

	describe "SELECT a, b FROM x WHERE a >= 2 OR b != 'foo' OR c = 2.0" do
	  it "creates a GET query for columns a and b from x with three filters for a >= 2 or b != 'foo' or c = 2.0" do
      query = nql.parse("SELECT a,b FROM x WHERE a >= 2 OR b != 'foo' OR c = 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b\nColumnHeaders: on\nFilter: a >= 2\nFilter: b != foo\nFilter: c = 2.0\nOr: 2\nOr: 2\n")
	  end
	end

	describe "SELECT * FROM x WHERE a >= 2 AND b != 'foo' OR c = 2.0" do
	  it "creates a GET query for all columns from x with a single filter for a >= 2 and b != 'foo', or c = 2.0" do
      query = nql.parse("SELECT * FROM x WHERE a >= 2 AND b != 'foo' OR c = 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a >= 2\nFilter: b != foo\nAnd: 2\nFilter: c = 2.0\nOr: 2\n")
	  end
	end

	describe "SELECT * FROM x WHERE a >= 2 OR b != 'foo' AND c = 2.0" do
	  it "creates a GET query for all columns from x with a single filter for a >= 2 or b != 'foo', and c = 2.0" do
      query = nql.parse("SELECT * FROM x WHERE a >= 2 OR b != 'foo' AND c = 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a >= 2\nFilter: b != foo\nFilter: c = 2.0\nAnd: 2\nOr: 2\n")
	  end
	end

	describe "SELECT a, b,c FROM x WHERE (a >= 2 OR b != 'foo') OR c = 2.0" do
	  it "creates a GET query for columns a and b from x with three filters for a >= 2 or b != 'foo', or c = 2.0" do
      query = nql.parse("SELECT a, b,c FROM x WHERE (a >= 2 OR b != 'foo') OR c = 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b c\nColumnHeaders: on\nFilter: a >= 2\nFilter: b != foo\nOr: 2\nFilter: c = 2.0\nOr: 2\n")
	  end
	end

	describe "SELECT a, b,c FROM x WHERE (a >= 2 AND b != 'foo') OR c = 2.0" do
	  it "creates a GET query for columns a and b from x with three filters for a >= 2 and b != 'foo', or c = 2.0" do
      query = nql.parse("SELECT a, b,c FROM x WHERE (a >= 2 AND b != 'foo') OR c = 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b c\nColumnHeaders: on\nFilter: a >= 2\nFilter: b != foo\nAnd: 2\nFilter: c = 2.0\nOr: 2\n")
	  end
	end

	describe "SELECT a, b,c FROM x WHERE (a >= 2 OR b != 'foo') AND c = 2.0" do
	  it "creates a GET query for columns a and b from x with three filters for a >= 2 or b != 'foo', and c = 2.0" do
      query = nql.parse("SELECT a, b,c FROM x WHERE (a >= 2 OR b != 'foo') AND c = 2.0")
	    query.should eq("GET x\nResponseHeader: fixed16\nColumns: a b c\nColumnHeaders: on\nFilter: a >= 2\nFilter: b != foo\nOr: 2\nFilter: c = 2.0\nAnd: 2\n")
	  end
	end

	describe "SELECT * FROM x WHERE a is null" do
	  it "creates a GET query for all columns from x with a single filter for a is null" do
      query = nql.parse("SELECT * FROM x WHERE a is null")
	    query.should eq("GET x\nResponseHeader: fixed16\nFilter: a\n")
	  end
	end
end
