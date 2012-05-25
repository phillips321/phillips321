/*
 * onesixtyone version 0.8 Copyright (C) 2002 solareclipse@phreedom.org
 * 
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along 
 * with this program; if not, write to the Free Software Foundation, Inc., 
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 * 
 * Fixed 13/10/2005 (john@ev6.net) No longer uses a fixed size array to
 * hold communities and hosts.. Should scale to any number of hosts or
 * communities 
 *
 * Fixed 28/03/2006 (larkmowe@gmail.com) -w option now works.  Spaces allowed
 * in communitry strings read from files.
 *
 * Fixed 25/05/2012 (about.me/r.hicks) -p option allows you to specify a custom port other than 161 to scan.
 * Fixed 25/05/2012 (about.me/r.hicks) fixed underlying issue with outputting custom port numbers to the screen. Cosmetic.
 * 
 */

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

/*
 * the defaults 
 */
int             community_count = 2;
char           *community[] = { "public", "private" };

#ifndef INADDR_NONE		/* Solaris is broken */
#define INADDR_NONE -1
#endif

char           *snmp_errors[] = {
    "NO ERROR",			/* 0 */
    "TOO BIG",			/* 1 */
    "NO SUCH NAME",		/* 2 */
    "BAD VALUE",		/* 3 */
    "READ ONLY",		/* 4 */
    "GENERIC ERROR",		/* 5 */
    "NO ACCESS",		/* 6 */
    "WRONG TYPE",		/* 7 */
    "WRONG LENGTH",		/* 8 */
    "WRONG ENCODING",		/* 9 */
    "WRONG VALUE",		/* 10 */
    "NO CREATION",		/* 11 */
    "INCONSISTENT VALUE",	/* 12 */
    "RESOURCE UNAVAILABLE",	/* 13 */
    "COMMIT FAILED",		/* 14 */
    "UNDO FAILED",		/* 15 */
    "AUTHORIZATION ERROR",	/* 16 */
    "NOT WRITABLE",		/* 17 */
    "INCONSISTENT NAME",	/* 18 */
};

struct {
    int             debug;
    int             log;
    int             quiet;
    int             port;
    char	    portStr[5];
    long            wait;

    FILE           *log_fd;
} o;

char            community_filename[250];
char            input_filename[250];

int             host_count = 0;

char            singlehost[64];

void
usage(char *cmdline)
{
    printf("onesixtyone v0.8 ( http://about.me/r.hicks )\n");
    printf("             Source at www.phillips321.co.uk\n");
    printf("Based on modified onesixtyone by http://labs.portcullis.co.uk/application/onesixtyone/\n");
    printf("Based on original onesixtyone by solareclipse@phreedom.org\n");
    printf("\n");
    printf("Usage: onesixtyone [options] <host> <community>\n");
    printf("  -c <communityfile> file with community names to try\n");
    printf("  -i <inputfile>     file with target hosts\n");
    printf("  -o <outputfile>    output log\n");
    printf("  -d                 debug mode, use twice for more information\n\n");
    printf("  -p <portnumber>    specify a non-standard port to scan against\n\n");
    printf("  -w n               wait n milliseconds (1/1000 of a second) between sending packets (default 10)\n");
    printf("  -q                 quiet mode, do not print log to stdout, use with -l\n");
    printf("examples: %s -c dict.txt 192.168.4.1 public\n", cmdline);
    printf("          %s -c dict.txt -i hosts -o my.log -w 100\n\n", cmdline);
}

void
read_communities(char *filename)
{
    FILE           *fd;
    int             i,
                    c;
    char            ecom[1024];

    if (o.debug > 0)
	printf("Using community file %s\n", filename);

    if ((fd = fopen(filename, "r")) == 0) {
	printf("Error opening community file %s\n", filename);
	return;
    }

    i = 0;
    c = 0;
    /*
     * loop 1, determine number of lines 
     */
    while (fgets(ecom, sizeof(ecom), fd)) {
	i++;
    }

    community_count = i;
    fclose(fd);
}

void
read_hosts(char *filename)
{
    FILE           *fd;
    char
                    ecom[1024];

    host_count = 0;

    if ((fd = fopen(filename, "r")) == 0) {
	printf("Error opening hosts file %s\n", filename);
	return;
    }

    /*
     * loop 1, determine number of lines 
     */
    while (fgets(ecom, sizeof(ecom), fd)) {
	host_count++;
    }

    if (o.debug > 0)
	printf("%d hosts read from file\n", host_count);
}

void
logfx(char *fmt, ...)
{
    va_list         args;
    va_start(args, fmt);
    if (o.log)
        vfprintf(o.log_fd, fmt, args);
    if (!o.quiet)
        vprintf(fmt, args);
    va_end(args);
}

void
init_options(int argc, char *argv[])
{
    char            log_filename[255];
    int             input_file;
    int             community_file;

    int             arg;

    o.debug = 0;
    o.log = 0;
    o.quiet = 0;
    o.wait = 10;
    o.port = 161;
    input_file = 0;
    community_file = 0;

    o.log_fd = NULL;

    while ((arg = getopt(argc, argv, "c:di:o:p:w:q")) != EOF) {
	switch (arg) {
	case 'c':
	    community_file = 1;
	    strncpy(community_filename, optarg,
		    sizeof(community_filename));
	    break;
	case 'd':
	    o.debug++;
	    break;
	case 'i':
	    input_file = 1;
	    strncpy(input_filename, optarg, sizeof(input_filename));
	    break;
	case 'o':
	    o.log = 1;
	    strncpy(log_filename, optarg, sizeof(log_filename));
	    break;
	case 'w':
	    o.wait = atol(optarg);	/* convert to nanoseconds */
	    break;
	case 'q':
	    o.quiet = 1;
	    break;
	case 'p':
		o.port = atoi(optarg); /*added ability to specify a port */
		strncpy(o.portStr,optarg,sizeof(o.portStr));
		break;
	case '?':
	    usage(argv[0]);
	    exit(1);
	    break;
	}
    }

    if (o.debug) {
	if (o.debug > 0)
	    printf("Debug level %d\n", o.debug);
    }

    if (!input_file) {
	if (optind >= argc) {
	    usage(argv[0]);
	    exit(1);
	}

	snprintf(singlehost, sizeof(singlehost), "%s", argv[optind++]);
	host_count = 1;
	if (o.debug > 0)
	    printf("Target ip read from command line: %s\n",
		   argv[optind - 1]);
    } else {
	read_hosts((char *) &input_filename);
    }

    if (community_file) {
	read_communities((char *) &community_filename);
    }

    if (optind < argc) {
	if (community_file) {
	    usage(argv[0]);
	    exit(1);
	}
	community[0] = argv[optind++];
	community_count = 1;
	if (o.debug > 0)
	    printf("Community read from command line: %s\n",
		   community[0]);;
    }

    if (optind < argc) {
	usage(argv[0]);
	exit(1);
    }

    if (o.log) {
	if ((o.log_fd = fopen(log_filename, "w")) == 0) {
	    printf("Error opening log file %s\n", log_filename);
	    exit(1);
	}
	printf("Logging to file %s\n", log_filename);
		if(o.port != 161){
			char * s = malloc(snprintf(NULL, 0, "%s %d", "Non-standard port selected - scanning port:\n", o.port) + 1);
			sprintf(s, "%s %d\n", "Non-standard port selected - scanning port:", o.port); 
			logfx(s);
		}		
    } else if (o.quiet) {
	printf
	    ("Warning: quiet mode specified without logging, you will lose your scan results\n");
    }

    /*
     * if (o.debug > 0) { printf("%d communities:", community_count); for
     * (i=0; i < community_count; i++) printf(" %s", community[i]);
     * printf("\n"); } 
     */
    if (o.debug > 0) {
	printf("%d communities\n", community_count);
    }

    if (o.debug > 0)
	printf("Waiting for %ld milliseconds between packets\n", o.wait);
}

int
build_snmp_req(char *buf, int buf_size, char *community)
{
    int             i;
    static int      id;
    char            object[] =
	"\x30\x0e\x30\x0c\x06\x08\x2b\x06\x01\x02\x01\x01\x01\x0\x05\x00";

    if (21 + strlen(community) + strlen(object) > buf_size) {
	printf("SNMP packet length exceeded.\nCommunity: %s\nObject: %s\n",
	       community, object);
	exit(1);
    }

    if (--id > 0x7ffe)
	id = 0;

    memset(buf, 0, buf_size);

    buf[0] = 0x30;
    buf[1] = 19 + strlen(community) + sizeof(object) - 1;

    /*
     * Version: 1 
     */
    buf[2] = 0x02;
    buf[3] = 0x01;
    buf[4] = 0x00;

    /*
     * Community 
     */
    buf[5] = 0x04;
    buf[6] = strlen(community);

    strcpy((buf + 7), community);
    i = 7 + strlen(community);

    /*
     * PDU type: GET 
     */
    buf[i++] = ' ';
    buf[i++] = 12 + sizeof(object) - 1;

    /*
     * Request ID 
     */
    buf[i++] = 0x02;
    buf[i++] = 0x04;
    buf[i++] = (char) ((id >> 24) & 0xff);
    buf[i++] = (char) ((id >> 16) & 0xff);
    buf[i++] = (char) ((id >> 8) & 0xff);
    buf[i++] = (char) ((id >> 0) & 0xff);

    /*
     * Error status: no error 
     */
    buf[i++] = 0x02;
    buf[i++] = 0x01;
    buf[i++] = 0x00;

    /*
     * Error index 
     */
    buf[i++] = 0x02;
    buf[i++] = 0x01;
    buf[i++] = 0x00;

    /*
     * Object ID 
     */
    memcpy((char *) &buf[i], &object, sizeof(object) - 1);
    i = i + sizeof(object) - 1;

    return (i);
}

int
parse_asn_length(u_char * buf, int buf_size, int *i)
{
    int             len;
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[*i] < 0x81) {
	len = buf[*i];
	*i += 1;
    } else if (buf[*i] == 0x81) {
	*i += 1;
	if ((*i) + 1 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	len = buf[*i];
	*i += 1;
    } else if (buf[*i] == 0x82) {
	*i += 1;
	if ((*i) + 2 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	len = (buf[*i] << 8) + buf[(*i) + 1];
	*i += 2;
    } else if (buf[*i] == 0x83) {
	*i += 1;
	if ((*i) + 3 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	len = (buf[*i] << 16) + (buf[(*i) + 1] << 8) + buf[(*i) + 2];
	*i += 3;
    } else if (buf[*i] == 0x84) {
	*i += 1;
	if ((*i) + 4 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	len =
	    (buf[*i] << 24) + (buf[(*i) + 1] << 16) +
	    (buf[(*i) + 2] << 8) + buf[(*i) + 3];
	*i += 4;
    } else {
	logfx("Unable to decode SNMP packet: wrong length\n");
	return -1;
    }

    if ((*i) + len > buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    return len;
}

int
skip_asn_length(u_char * buf, int buf_size, int *i)
{
    int             ret;

    if ((ret = parse_asn_length(buf, buf_size, i)) > 0)
	*i += ret;

    return ret;
}

int
parse_asn_integer(u_char * buf, int buf_size, int *i)
{
    int             ret;

    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[*i] == 0x81) {
	*i += 1;
	if (*i >= buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
    }

    if (buf[*i] == 0x01) {
	if ((*i) + 2 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	ret = (int) buf[(*i) + 1];
	*i += 2;
    } else if (buf[*i] == 0x02) {
	if ((*i) + 3 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	ret = ((int) buf[(*i) + 1] << 8) + (int) buf[(*i) + 2];
	*i += 3;
    } else if (buf[*i] == 0x04) {
	if ((*i) + 5 > buf_size) {
	    logfx("Unable to decode SNMP packet: buffer overflow\n");
	    return -1;
	}
	ret = ((int) buf[(*i) + 1] << 24) +
	    ((int) buf[(*i) + 2] << 16) +
	    ((int) buf[(*i) + 3] << 8) + (int) buf[(*i) + 4];
	*i += 5;
    } else {
	logfx
	    ("Unable to decode SNMP packet: unrecognized integer length\n");
	return -1;
    }

    return ret;
}

int
print_asn_string(u_char * buf, int buf_size, int *i)
{
    int             ret;
    int             string_end;

    if ((ret = parse_asn_length(buf, buf_size, i)) == -1)
	return -1;
    else
	string_end = *i + ret;

    for (; *i < string_end; *i += 1) {
	if (buf[*i] < 0x20 || buf[*i] > 0x80)
	    logfx(" ");
	else
	    logfx("%c", buf[*i]);
    }

    return 0;
}

int
parse_snmp_header(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x30) {
	logfx("Unable to decode SNMP packet: wrong header\n");
	return -1;
    }

    if (parse_asn_length(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

int
parse_snmp_version(u_char * buf, int buf_size, int *i)
{
    int             ret;

    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x02) {
	logfx("Unable to decode SNMP packet: snmp version invalid\n");
	return -1;
    }

    if ((ret = parse_asn_integer(buf, buf_size, i)) == -1)
	return -1;
    else if (ret != 0) {
	logfx("Unable to decode SNMP packet: snmp version invalid\n");
	return -1;
    }

    return 0;
}

int
parse_snmp_community(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x04) {
	logfx("Unable to decode SNMP packet: community name not found\n");
	return -1;
    }

    logfx("[");
    if (print_asn_string(buf, buf_size, i) == -1)
	return -1;
    logfx("] ");

    return 0;
}

int
parse_snmp_pdu(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0xa2) {
	logfx
	    ("Unable to decode SNMP packet: PDU type not RESPONSE (0xa2)\n");
	return -1;
    }

    if (parse_asn_length(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

int
parse_snmp_requestid(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x02) {
	logfx("Unable to decode SNMP packet: request id invalid\n");
	return -1;
    }
    if (parse_asn_integer(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

int
parse_snmp_errorcode(u_char * buf, int buf_size, int *i)
{
    int             ret;

    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x02) {
	logfx("Unable to decode SNMP packet: error code invalid\n");
	return -1;
    }
    if ((ret = parse_asn_integer(buf, buf_size, i)) < 0)
	return -1;
    if (ret != 0) {
	if (ret < 0 || ret > 18) {
	    logfx("Unable to decode SNMP packet: error code invalid\n");
	    return -1;
	}
	logfx("Host responded with error %s\n", snmp_errors[ret]);
	return -1;
    }

    return 0;
}

int
parse_snmp_errorindex(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x02) {
	logfx("Unable to decode SNMP packet: error index invalid\n");
	return -1;
    }
    if (parse_asn_integer(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

int
parse_snmp_objheader(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x30) {
	logfx("Unable to decode SNMP packet: invalid object header\n");
	return -1;
    }
    if (parse_asn_length(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

int
parse_snmp_objheader6(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x06) {
	logfx("Unable to decode SNMP packet: invalid object header\n");
	return -1;
    }
    if (skip_asn_length(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

int
parse_snmp_value(u_char * buf, int buf_size, int *i)
{
    if (*i >= buf_size) {
	logfx("Unable to decode SNMP packet: buffer overflow\n");
	return -1;
    }

    if (buf[(*i)++] != 0x04) {
	logfx("Unable to decode SNMP packet: invalid value\n");
	return -1;
    }
    if (print_asn_string(buf, buf_size, i) < 0)
	return -1;

    return 0;
}

void
parse_snmp_response(u_char * buf, int buf_size)
{
    int             i;

    i = 0;

    if (parse_snmp_header(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_version(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_community(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_pdu(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_requestid(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_errorcode(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_errorindex(buf, buf_size, &i) == -1)
	return;

    /*
     * Bug in an HP JetDirect 
     */
    if (i + 3 <= buf_size && buf[i] == 0x00 && buf[i + 1] == 0x30
	&& buf[i + 2] == 0x20)
	i += 3;

    if (parse_snmp_objheader(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_objheader(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_objheader6(buf, buf_size, &i) == -1)
	return;
    if (parse_snmp_value(buf, buf_size, &i) == -1) {
    	// If value isn't parsed we still need a CR or the
	// next response will be displayed on this line.
        logfx("\n");
	return;
    }

    logfx("\n");
}

/*
 * Subtract the `struct timeval' values X and Y, storing the result in
 * RESULT. Return 1 if the difference is negative, otherwise 0. 
 */

inline int
timeval_subtract(struct timeval *result, struct timeval *x,
		 struct timeval *y)
{
    int             nsec;

    /*
     * Perform the carry for the later subtraction by updating y. 
     */
    if (x->tv_usec < y->tv_usec) {
	nsec = (y->tv_usec - x->tv_usec) / 1000000 + 1;
	y->tv_usec -= 1000000 * nsec;
	y->tv_sec += nsec;
    }
    if (x->tv_usec - y->tv_usec > 1000000) {
	nsec = (x->tv_usec - y->tv_usec) / 1000000;
	y->tv_usec += 1000000 * nsec;
	y->tv_sec -= nsec;
    }

    /*
     * Compute the time remaining to wait. tv_usec is certainly positive. 
     */
    result->tv_sec = x->tv_sec - y->tv_sec;
    result->tv_usec = x->tv_usec - y->tv_usec;

    /*
     * Return 1 if result is negative. 
     */
    return x->tv_sec < y->tv_sec;
}

void
receive_snmp(int sock, long wait, struct sockaddr_in *remote_addr)
{
    struct timeval  tv_now,
                    tv_until,
                    tv_wait;
    unsigned int    remote_addr_len;
    char            buf[1500];
    int             ret;
    fd_set          fds;

    gettimeofday(&tv_now, NULL);
    tv_until.tv_sec = tv_now.tv_sec;
    tv_until.tv_usec = tv_now.tv_usec + wait * 1000;
    if (tv_until.tv_usec >= 1000000) {
	tv_until.tv_sec += tv_until.tv_usec / 1000000;
	tv_until.tv_usec = tv_until.tv_usec % 1000000;
    }

    tv_wait.tv_sec = wait / 1000;
    tv_wait.tv_usec = wait % 1000 * 1000;

    do {
	/*
	 * Put the socket into the fd set 
	 */
	FD_ZERO(&fds);
	FD_SET(sock, &fds);

	if ((ret = select(sock + 1, &fds, NULL, NULL, &tv_wait)) == -1) {
	    printf("Error in pselect\n");
	    exit(1);
	} else if (ret > 0) {
	    memset(&buf, 0x0, sizeof(buf));
	    remote_addr_len = sizeof(*remote_addr);

	    ret =
		recvfrom(sock, &buf, sizeof(buf), 0,
			 (struct sockaddr *) remote_addr,
			 &remote_addr_len);
	    if (ret < 0) {
		printf("Error in recvfrom\n");
	    }
	    logfx("%s ", inet_ntoa(remote_addr->sin_addr));
	    parse_snmp_response((u_char *) & buf, ret);
	    if (o.log)
		fflush(o.log_fd);
	}

	gettimeofday(&tv_now, NULL);
    }
    while (timeval_subtract(&tv_wait, &tv_until, &tv_now) == 0);
}

int
main(int argc, char *argv[])
{
    struct sockaddr_in local_addr;
    struct sockaddr_in remote_addr;
    int             sock;
    int             ret;
    int             c;
    char            sendbuf[1500],
                    combuf[128],
                    hostbuf[64];
    int             sendbuf_size,
                    hostfile = 1;
    FILE           *com,
                   *hostfd;

    init_options(argc, argv);

    /*
     * socket creation 
     */
    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
	printf("Error creating socket\n");
	exit(1);
    }

    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htons(0);

    ret = bind(sock, (struct sockaddr *) &local_addr, sizeof(local_addr));
    if (ret < 0) {
	printf("Error binding socket\n");
	exit(1);
    }

    /*
     * remote address 
     */
    remote_addr.sin_family = AF_INET;
    remote_addr.sin_port = htons(o.port);

    printf("Scanning %d hosts, %d communities\n", host_count,
	   community_count);

    /*
     * iterate through communities 
     */
    /*
     * community[] is pointer to char 
     */

    /*
     * for (c=0; c < community_count; c++) { 
     */
    /*
     * read community file, iterate 
     */
    if ((com = fopen(community_filename, "r")) == NULL) {
	/*
	 * No communities file, use defaults 
	 */
	printf("No communities file, using default\n");
    }
    if ((hostfd = fopen(input_filename, "r")) == NULL) {
	printf("Cant open hosts file, scanning single host: %s\n",
	       singlehost);
	hostfile = 0;
    }

    if (com != NULL) {
	while (fgets(combuf, sizeof(combuf), com)) {
	    // Chop \n off end of combuf.  Don't sscanf or community strings won't be allowed to contain spaces.
	    combuf[strlen(combuf) - 1] = '\0';
	    if (o.debug > 0)
		printf("Trying community %s\n", combuf);
	    sendbuf_size =
		build_snmp_req((char *) &sendbuf, sizeof(sendbuf), combuf);

	    /*
	     * now iterate hosts 
	     */
	    if (hostfd != NULL) {
		while (fgets(hostbuf, sizeof(hostbuf), hostfd)) {
		    remote_addr.sin_addr.s_addr = inet_addr(hostbuf);
		    if (o.debug > 1)
			printf("Sending to ip %s\n",
			       inet_ntoa(*(struct in_addr *) &remote_addr.
					 sin_addr.s_addr));

		    ret =
			sendto(sock, &sendbuf, sendbuf_size, 0,
			       (struct sockaddr *) &remote_addr,
			       sizeof(remote_addr));
		    if (ret < 0) {
		        printf("Error in sendto while sending to %s: %s\n", inet_ntoa(*(struct in_addr *) &remote_addr.sin_addr.s_addr), strerror(errno));
			/*
			 * exit(1); 
			 */
		    }

		    // receive packets and wait a bit
		    receive_snmp(sock, o.wait, &remote_addr);
		}
		rewind(hostfd);
	    } else {		/* no hostfile */
		remote_addr.sin_addr.s_addr = inet_addr(singlehost);
		if (o.debug > 1)
		    printf("Sending to ip %s\n",
			   inet_ntoa(*(struct in_addr *) &remote_addr.
				     sin_addr.s_addr));
		ret =
		    sendto(sock, &sendbuf, sendbuf_size, 0,
			   (struct sockaddr *) &remote_addr,
			   sizeof(remote_addr));
		if (ret < 0) {
		    printf("Error in sendto while sending to %s: %s\n", inet_ntoa(*(struct in_addr *) &remote_addr.sin_addr.s_addr), strerror(errno));
		    /*
		     * exit(1); 
		     */
		}

		// receive packets and wait a bit
		receive_snmp(sock, o.wait, &remote_addr);

	    }
	}
    } else {			/* no comfile */
	for (c = 0; c < community_count; c++) {
	    if (o.debug > 0)
		printf("Trying community %s\n", community[c]);

	    sendbuf_size =
		build_snmp_req((char *) &sendbuf, sizeof(sendbuf),
			       community[c]);
	    if (hostfd != NULL) {
		while (fgets(hostbuf, sizeof(hostbuf), hostfd)) {
		    remote_addr.sin_addr.s_addr = inet_addr(hostbuf);
		    if (o.debug > 1)
			printf("Sending to ip %s\n",
			       inet_ntoa(*(struct in_addr *) &remote_addr.
					 sin_addr.s_addr));

		    ret =
			sendto(sock, &sendbuf, sendbuf_size, 0,
			       (struct sockaddr *) &remote_addr,
			       sizeof(remote_addr));
		    if (ret < 0) {
		        printf("Error in sendto while sending to %s: %s\n", inet_ntoa(*(struct in_addr *) &remote_addr.sin_addr.s_addr), strerror(errno));
			/*
			 * exit(1); 
			 */
		    }

		    // receive packets and wait a bit
		    receive_snmp(sock, o.wait, &remote_addr);
		}
		rewind(hostfd);
	    } else {		/* no hostfile */
		remote_addr.sin_addr.s_addr = inet_addr(singlehost);
		if (o.debug > 1)
		    printf("Sending to ip %s\n",
			   inet_ntoa(*(struct in_addr *) &remote_addr.
				     sin_addr.s_addr));
		ret =
		    sendto(sock, &sendbuf, sendbuf_size, 0,
			   (struct sockaddr *) &remote_addr,
			   sizeof(remote_addr));
		if (ret < 0) {
		    printf("Error in sendto while sending to %s: %s\n", inet_ntoa(*(struct in_addr *) &remote_addr.sin_addr.s_addr), strerror(errno));
		    /*
		     * exit(1); 
		     */
		}

		// receive packets and wait a bit
		receive_snmp(sock, o.wait, &remote_addr);
	    }
	}
    }
    if (o.debug > 0)
	printf("All packets sent, waiting for responses.\n");

    /*
     * wait for 5 seconds 
     */
    receive_snmp(sock, 5000, &remote_addr);

    if (o.debug > 0)
	printf("done.\n");

    if (o.log)
	fclose(o.log_fd);

    return 0;
}
