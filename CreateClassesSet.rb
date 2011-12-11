

$scanFolder = ARGV[0]
$outFile = $scanFolder+'ClassesSet.m'

if(!$scanFolder )
  p 'waiting folder'
  
  exit
end
  
def ScanSourceFile(filePath)
  
  text = File.open(filePath, 'r'){ |file| file.read }

 impArray = text.scan(/@implementation [a-zA-Z0-9]+/)
 impArray.each{ |item|

    item["@implementation"] = ""
    item = item.delete(" ")
    #p item
    File.open($outFile, 'a'){ |file| file.puts  '@"'+ item + '",' }

  }
  
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

text = <<EOS

#import <Foundation/Foundation.h>
#import "ClassesSet.h"

NSSet* classesSet = nil;

void initClassSet()
{
    classesSet = [[NSSet alloc] initWithArray: [NSArray arrayWithObjects:
EOS

File.open($outFile, 'w'){ |file| file.puts  text }

ScanFolder($scanFolder)

text = <<EOS
nil]];
}
    
EOS

File.open($outFile, 'a'){ |file| file.puts  text }

p 'finished'
