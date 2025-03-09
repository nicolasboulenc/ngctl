
/*
todo:
- config file needs to include absolute paths
*/

#include <iostream>
#include <cstring>
#include <fstream>
#include <print>
#include <vector>
#include <filesystem>


const unsigned int PORT_DEFAULT = 8080;


constexpr const char *site_template = 
    "server {{\n"
    "	listen {};\n"
    "	root {};\n"
    "	location / {{\n"
    "		try_files $uri $uri/ =404;\n"
    "	}}\n"
    "}}";


constexpr const char *help_template = 
    "Usage: ngctl [COMMAND] [PATH] [PORT]\n"
    "Easily manage nginx conf files\n\n"
    "  start [PATH=.] [PORT={0}]    Starts a server with path as root. If not port is provided, will use first available port from 8080.\n"
    "  add   [PATH=.] [PORT={0}]    Alias for start.\n"
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


void get_sites(const conf_t &conf, std::vector<site_t> &sites) {

    try {
        for (const auto &entry : std::filesystem::directory_iterator(conf.enabled)) {
            site_t site;
            get_site(entry.path().string(), site);
            sites.push_back(site);
        }
    }
    catch(std::filesystem::filesystem_error &er) {}

    try {
        for (const auto &entry : std::filesystem::directory_iterator(conf.available)) {
            site_t site;
            get_site(entry.path().string(), site);
            sites.push_back(site);
        }
    }
    catch(std::filesystem::filesystem_error &er) {}
}


int get_first_available_port(const conf_t &conf, const int &port_default=PORT_DEFAULT) {

    std::vector<site_t> sites;
    get_sites(conf, sites);

    int port = port_default;
    size_t sites_count = sites.size();

    while(true) {
        int i=0;
        while(i < sites_count && sites[i].port != port) {
            i++;
        }
        if(i == sites_count) {
            break;
        }
        port++;
    }
    return port;
}


int main(int argc, char** argv) {

    conf_t conf;
    get_conf(&conf);

    if(argc > 1) {

        if(strcmp(argv[1], "start") == 0 || strcmp(argv[1], "add") == 0) {

			int port = -1;
            std::string root = "";

			// process args into root and port
            for(int i=2; i<argc; i++) {

                std::string arg = argv[i];

                try {
                    std::size_t pos;
                    port = std::stoi(arg, &pos, 10);
                }
                catch (std::invalid_argument const& ex) { }

                if(port == -1) {
                    // this must be a path
                    if(std::filesystem::exists(arg) == true) {
                        root = arg;
                    }
                    else {
                        std::println("Error: root does not exist!");
                    }
                }
            }

            if(root.compare("") == 0) {
                root = std::filesystem::current_path();
            }

            std::string filename = "ngctl";
            filename.append(root);
            while(true) {
                std::string::size_type pos = filename.find_first_of("/");
                if(pos == std::string::npos) break;
                filename.replace(pos, 1, ".");
            }

            std::string en = conf.enabled;
            std::string av = conf.available;
            en.append(filename);
            av.append(filename);

            if(port == -1 && (std::filesystem::exists(en) || std::filesystem::exists(av))) {
                if(std::filesystem::exists(en)) {
                    // move file from available to enabled
                    std::filesystem::rename(av, en);
                }
            }
            else {
                if(port == -1) {
                    port = get_first_available_port(conf);
                }

                // write to file
                std::ofstream os(en, std::ios::binary);
                std::println(os, site_template, port, root);
            }
            std::system("nginx -t");
            std::system("nginx -s reload");
			// nginx -t &>/dev/null
			// nginx -s reload &>/dev/null
			std::println("location enabled: {}", root);
			std::println(" --> http://localhost:{}/", port);
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
