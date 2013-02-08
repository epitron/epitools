require 'epitools/term'

describe Term do

  it "sizes" do
    width, height = Term.size
    width.class.should == Fixnum
    height.class.should == Fixnum
  end

  it "tables" do
    table = Term::Table[ (1..1000).to_a ]
    #p [:cols, table.num_columns]
    #p [:rows, table.num_rows]
    #puts "columns"
    #puts table.by_columns :border=>true
    #puts "rows"
    #puts table.by_rows 
    puts table.by_rows

    table.by_columns.should_not be_nil
    table.by_rows.should_not be_nil

    table.border = true
    
    table.by_columns.should_not be_nil
    table.by_rows.should_not be_nil

  end
  
  it "tables nothing" do
    table = Term::Table.new []
    lambda { table.by_rows }.should_not raise_error
    lambda { table.by_columns }.should_not raise_error
  end
  
end

