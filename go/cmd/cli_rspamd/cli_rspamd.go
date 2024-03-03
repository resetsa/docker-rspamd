package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"resetsa/client_rspamd/internal/rspam"
	"time"
)

const (
	SPAM_EXITCODE  = 0
	CLEAN_EXITCODE = 1
	DEFAULT_URL    = "http://127.0.0.1:11333"
)

func Usage() {
	fmt.Printf("Usage:\n%s -m <path_to_eml> [-u <url_rspamd>]\n", filepath.Base(os.Args[0]))
	fmt.Printf("Default:\n url_rspamd = %s\n", DEFAULT_URL)
}

func main() {
	var filePath, urlRspam string
	flag.StringVar(&filePath, "m", "", "EML for check")
	flag.StringVar(&urlRspam, "u", DEFAULT_URL, "URL of rspamd")
	flag.Parse()

	if filePath == "" {
		Usage()
		log.Println("EML file is required")
		os.Exit(SPAM_EXITCODE)
	}

	start := time.Now()
	file, err := os.Open(filePath)
	if err != nil {
		log.Printf("error on open file: %v", err)
		os.Exit(SPAM_EXITCODE)
	}
	defer file.Close()
	rs := rspam.New(urlRspam, 30*time.Second)
	rs.GenerateReq(file)
	rs.SetID(filepath.Base(filePath))
	reqStart := time.Now()
	if err := rs.SendReq(); err != nil {
		log.Printf("error on request:%v", err)
		os.Exit(SPAM_EXITCODE)
	}
	reqEnd := time.Now()
	if err := rs.ParseAnswer(); err != nil {
		log.Printf("error on parse result: %v", err)
	}
	end := time.Now()
	log.Printf("file %s: %v; runtime=%v, req_runtime=%v", filePath, rs.Answer(), end.Sub(start), reqEnd.Sub(reqStart))
	if rs.Answer().Score < rs.Answer().RequiredScore {
		os.Exit(CLEAN_EXITCODE)
	}
	os.Exit(SPAM_EXITCODE)
}
