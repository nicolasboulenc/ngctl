
/*
g++ 
todo:
- config file needs to include absolute paths
*/

#include <iostream>
#include <cstring>
#include <fstream>
#include <print>
#include <filesystem>


const char *site_template = 
    "server {\n"
    "  listen %i;\n"
    "  root %s;\n"
    "  location / {\n"
    "    try_files $uri $uri/ =404;\n"
    "  }\n"
    "}\n";


const unsigned int PORT_DEFAULT = 8080;

constexpr char *help_template = 
    "Usage: ngctl [COMMAND] [PATH] [PORT]\n"
    "Easily manage nginx conf files\n\n"
    "  start [PATH=.] [PORT={}]    Starts a server with path as root. If not port is provided, will use first available port from 8080.\n"
    "  add   [PATH=.] [PORT={}]    Alias for start.\n"
    "  del   [PATH]                NOT IMPLEMENTED\n"
    "  ls                          List all servers, enabled and available.\n"
    "  enable                      Enable a previously disabled server.\n"
    "  disable                     Disable a previously enabled server.\n"
    "  version                     Display version information.\n";


struct conf_t {
    std::string install;
    std::string enabled;
    std::string available;
};


struct site_t {
    std::string root;
    unsigned int port;
};


void trim(std::string &text) {

    std::string_view v = text;
    v.remove_prefix(std::min(v.find_first_not_of(" "), v.size()));
    v.remove_suffix(v.size() - v.find_last_not_of(" ") - 1);
    text = v;
}


void get_conf(conf_t *conf) {

    using std::string;

    std::ifstream infile("./ngctl.yml");
    string line;
    string::size_type s = 0;

    while (std::getline(infile, line)) {

        if((s = line.find("install")) != std::string::npos) {
            string::size_type start = line.find("\"") + 1;
            string::size_type end = line.rfind("\"");
            conf->install = line.substr(start, end - start);
        }
        else if((s = line.find("enabled"))  != std::string::npos) {
            string::size_type start = line.find("\"") + 1;
            string::size_type end = line.rfind("\"");
            conf->enabled = line.substr(start, end - start);
        }
        else if((s = line.find("available"))  != std::string::npos) {
            string::size_type start = line.find("\"") + 1;
            string::size_type end = line.rfind("\"");
            conf->available = line.substr(start, end - start);
        }
    }
}


void get_site(std::string filename, site_t &site) {

    using std::string;

    std::ifstream infile(filename);
    std::string line;
    string::size_type s = 0;

    while (std::getline(infile, line)) {
        if((s = line.find("root")) != std::string::npos) {
            string::size_type start = s + 4;                // length of "root"
            string::size_type end = line.rfind(";");
            site.root = line.substr(start, end - start);
            trim(site.root);
        }
        else if((s = line.find("listen"))  != std::string::npos) {
            string::size_type start = s + 6;                // length of "listen"
            string::size_type end = line.rfind(";");
            string sport = line.substr(start, end - start);
            trim(sport);
            site.port = std::stoi(sport);
        }
    }    
}


int main(int argc, char** argv) {

    conf_t conf;
    get_conf(&conf);

    std::println("conf ****************************************************** ");
    std::println("install-path:    |{}|", conf.install);
    std::println("enabled-path:    |{}|", conf.enabled);
    std::println("available-path:  |{}|", conf.available);
    std::println("conf ****************************************************** ");

    // site_t site;
    // get_site("/home/nicolas/dev/ngctl/sites-enabled/ngctl.home.nicolas.dev.pixel-ui", site);
    // std::println("site:  |{}|  |{}|", site.root, site.port);

    if(argc > 1) {

        if(strcmp(argv[1], "start") == 0 || strcmp(argv[1], "add") == 0) {
            std::println("start");
        }
        else if(strcmp(argv[1], "del") == 0) {
            std::println("del");
        }
        else if(strcmp(argv[1], "ls") == 0) {

            site_t site;
            std::error_code ec;
            int i=0;

            std::string desc = "enabled";
            if(std::filesystem::exists(conf.enabled, ec) == true) {
                for(const auto& entry : std::filesystem::directory_iterator(conf.enabled)) {
                    get_site(entry.path(), site);
                    std::println("[{}] {:<32} http://localhost:{:<10} ({})", i, site.root, site.port, desc);
                    i++;
                }
            }

            desc = "available";
            if(std::filesystem::exists(conf.available, ec) == true) {
                for(const auto& entry : std::filesystem::directory_iterator(conf.available)) {
                    get_site(entry.path(), site);
                    std::println("[{}] {:<32} http://localhost:{:<10} ({})", i, site.root, site.port, desc);
                    i++;
                }
            }
        }
        else if(strcmp(argv[1], "enable") == 0) {
            std::println("enable");
        }
        else if(strcmp(argv[1], "disable") == 0) {
            std::println("disable");
        }
        else if(strcmp(argv[1], "version") == 0) {
            std::println("version");
        }
    }
    else {
        std::println(help_template, PORT_DEFAULT);
    }

    return 0;
}
