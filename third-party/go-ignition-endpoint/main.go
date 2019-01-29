package main

import (
	"context"
	"flag"
	"fmt"
    "io/ioutil"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
)

type key int

const (
	requestIDKey key = 0
)

var (
	listenAddr   string
    logger       *log.Logger
)

func main() {
    logger = log.New(os.Stdout, "coreos_endpoint: ", log.LstdFlags)

	flag.StringVar(&listenAddr, "listen-addr", ":8081", "server listen address")
	flag.Parse()

	router := http.NewServeMux()
	router.Handle("/", index())

	server := &http.Server{
		Addr:         listenAddr,
		Handler:      (logging(logger)(router)),
		ErrorLog:     logger,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  15 * time.Second,
	}

	done := make(chan bool)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)

	go func() {
		<-quit

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		server.SetKeepAlivesEnabled(false)
		if err := server.Shutdown(ctx); err != nil {
			logger.Fatalf("Could not gracefully shutdown the server: %v\n", err)
		}
		close(done)
	}()

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Fatalf("Could not listen on %s: %v\n", listenAddr, err)
	}

	<-done
}

func index() http.Handler {
    logger.Println("in index")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	    if r.URL.Path != "/" {
		    http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
        }

        if r.Method == "POST" {
            bodyBytes, _ := ioutil.ReadAll(r.Body)
            bodyString := string(bodyBytes)
            logger.Println("Post from website!", bodyString)
		    w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	        w.WriteHeader(http.StatusOK)
            fmt.Fprintln(w, "http://192.168.126.1/artifacts/stable_ignition/master.ign")
        }
	})
}

func logging(logger *log.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				requestID, ok := r.Context().Value(requestIDKey).(string)
				if !ok {
					requestID = "unknown"
				}
				logger.Println(requestID, r.Method, r.URL.Path, r.RemoteAddr, r.UserAgent())
			}()
			next.ServeHTTP(w, r)
		})
	}
}

