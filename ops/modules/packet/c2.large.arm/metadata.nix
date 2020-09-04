{
      # networking.hostName = "hostname1";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address =  "147.75.75.25";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:1800::";
        interface = "bond0";
      };
      networking.nameservers = [
        "147.75.207.207"
        "147.75.207.208"
      ];

      networking.bonds.bond0 = {
        driverOptions = {
          mode = "802.3ad";
          xmit_hash_policy = "layer3+4";
          lacp_rate = "fast";
          downdelay = "200";
          miimon = "100";
          updelay = "200";
        };

        interfaces = [
          "eth1" "eth2"
        ];
      };

      networking.interfaces.bond0 = {
        useDHCP = false;

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.22.128";
            }
          ];
          addresses = [
            {
              address = "147.75.75.26";
              prefixLength = 30;
            }
            {
              address = "10.99.22.129";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:1800::1";
              prefixLength = 127;
            }
          ];
        };
      };

      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC56/8uyJSPckjbtqqPGG2bJmm4yuziO3NTorgb41m2vW2ENucW1zuxFtraX0dfKp3fdYXonkIaKXYSmJnOwNDo+O9Jkwhy1yE7V88EssJE2uBsryoA/lcV2PEYryZuutFZkOlKUA6IuOPuS3cXeTaZfbV4+Mmb12nslGxMd/96IV9F4ZQR8FAZdIYfoTCh4aC9X/HQLLr5pY730rwFIFNx1kyDOdP0iM2829g1Afcvg7Q3XZ+WFP/s/rR15uiFpuUc+Cwtgv8oluFvne8xaB4Tvm9wu59vcNyW9YVgSCeMOFhYiJY/0HufoDUTNN9bcm052seZpZnRPsn1+2a0uxSN NixOps auto-generated key"

      ];

      users.users.root.initialHashedPassword = "$6$NdrU/LRGvMrjUxn/$uUETkBHvkThKDR.xebTKHT30ps01daZu3tE3ErHdiPMHniLDeeSrAabtqTd.8JufDtma0eiH2GF4DDQnAQ/79/";
     }
