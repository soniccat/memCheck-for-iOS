

scanFolder = ARGV[0]

if(!scanFolder)
  p 'waiting folder path in argument'
  
  exit
end
  
def ScanSourceFile(filePath)
  
  #p filePath
  
  text = File.open(filePath, 'r'){ |file| file.read }
  
  #impArray = text.scan(/@implementation [a-zA-Z]+/)
  deallocArray = text.scan(/\)[ ]*dealloc[ {]*[ \t]*$/)
  superDeallocArray = text.scan(/\[[ ]*super[ ]*dealloc[ ]*\]/)
  
  
  #p 'impArray count '+impArray.count.to_s + ' dealloc count '+deallocArray.count.to_s+' super dealloc count '+superDeallocArray.count.to_s
  
  if( deallocArray.count != superDeallocArray.count )    
    p filePath + ' dealloc count > super dealloc count'
    
    p deallocArray
    p superDeallocArray
  end

  
=begin
 impArray.each{ |item|

    item["@implementation"] = ""
    item = item.delete(" ")
    p item

  }
=end
  
  
end

def ScanFolder(folderName)
  
  dirObj = Dir.new(folderName)
  dirObj.each{ |fn|
  
    nextItem = dirObj.path + '/' + fn
  
    if(!File.directory?( nextItem ))
  
      if( fn =~ /\.m$/ ) 
        
        ScanSourceFile(nextItem)
        
      end
    
    else
      
      next if(fn==".." || fn=="." || fn==".git" || fn==".svn")
      
      ScanFolder(nextItem)
      
    end
  
  }
  
end

ScanFolder(scanFolder)
p 'finished'
