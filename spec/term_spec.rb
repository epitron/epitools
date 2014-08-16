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

    Term::Table do |table|
      100.times do |n|
        table.row do
          col "#{n}."
          col "A" * rand(10)
          col "B" * rand(10)
        end
      end
    end

    Term::Table[
      [1,2,3], 
      [4,5,6] 
    ]
    
    table = Term::Table.new
    table.rows = [ [1,2,3], [4,5,6] ]
    table.rows << [1,2,3]
    table.rows << [4,5,6]
    table.add_row [1,2,3,4,5]
  end
  
  it "tables nothing" do
    table = Term::Table.new []
    lambda { table.by_rows }.should_not raise_error
    lambda { table.by_columns }.should_not raise_error
  end
  
end

