
#include <iostream>
#include <iomanip>
#include <sstream>
#include <fstream>
#include <string>
#include <cstdio>
#include <sys/stat.h>

template<typename Type>
std::string toHex(Type num, int additionalLength=2)
{
    std::stringstream stream;
    stream
        << "0x" 
        << std::setfill ('0')
        << std::setw(additionalLength)
        << std::hex
        << (num & 0xFF)
    ;
    return stream.str();
}

#define safeName(n) std::string(n)

int main(int argc, char* argv[])
{
    int ch;
    size_t count;
    size_t size;
    std::string filename;
    std::string varname;
    std::fstream instream;
    std::ostream& outstream = std::cout;
    varname = (argc > 2) ? safeName(argv[2]) : "data_field";
    if(argc > 1)
    {
        filename = argv[1];
        instream.open(filename, std::ios::in | std::ios::binary);
        if(instream.good())
        {
            count = 0;
            size = 0;
            outstream << "static const unsigned char " << varname << "_data[] = \n{\n";
            while((ch = instream.get()) != EOF)
            {
                auto val = toHex(ch);
                outstream << val << ",";
                if(count == 20)
                {
                    outstream << std::endl << std::flush;
                    count = 0;
                }
                count++;
                size++;
            }
            outstream << "\n};\n" << std::flush;
            outstream << "static const unsigned int " << varname << "_size = " << size << ";\n";
            outstream << std::endl << std::flush;
        }
        else
        {
            std::cerr << "failed to open \"" << filename << "\" for reading" << std::endl;
            return 1;
        }
        return 0;
    }
    std::cerr
        << "usage: " << argv[0] << " <filename> [fieldname]" << std::endl
        << "writes data to stdout." << std::endl
    ;
    return 1;
}

