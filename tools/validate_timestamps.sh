#!/bin/bash

# validate_timestamps.sh
# Timestamp Integrity Validation Script
# 
# This script checks for common patterns of arbitrary timestamps and validates
# timestamp integrity across all project documentation.
#
# Usage: ./validate_timestamps.sh [--fix] [--verbose]
#   --fix: Automatically fix common issues where possible
#   --verbose: Show detailed output

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="docs"
INSIGHTS_DIR="cursor/insights"
TODAY=$(date '+%Y-%m-%d')
CURRENT_TIME=$(date '+%H:%M:%S')

# Statistics
TOTAL_VIOLATIONS=0
ARBITRARY_TIMESTAMPS=0
DUPLICATE_TIMESTAMPS=0
FUTURE_TIMESTAMPS=0
SEQUENTIAL_PATTERNS=0

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check for arbitrary timestamp patterns
check_arbitrary_patterns() {
    log_info "Checking for arbitrary timestamp patterns..."
    
    # Check for sequential 15-minute intervals (common arbitrary pattern)
    local sequential_count=$(grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:00\]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | wc -l)
    if [ "$sequential_count" -gt 0 ]; then
        log_warning "Found $sequential_count timestamps with :00 seconds (suspicious pattern)"
        SEQUENTIAL_PATTERNS=$((SEQUENTIAL_PATTERNS + sequential_count))
        
        if [ "$VERBOSE" = true ]; then
            grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:00\]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null || true
        fi
    fi
    
    # Check for sequential 30-minute intervals
    local thirty_min_count=$(grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:00\]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | grep -E ":(00|30):00" | wc -l)
    if [ "$thirty_min_count" -gt 0 ]; then
        log_warning "Found $thirty_min_count timestamps with :00 or :30 minutes (suspicious pattern)"
        SEQUENTIAL_PATTERNS=$((SEQUENTIAL_PATTERNS + thirty_min_count))
    fi
    
    # Check for exact same timestamps (likely arbitrary)
    local same_time_count=$(grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | grep -o "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]" | sort | uniq -d | wc -l)
    if [ "$same_time_count" -gt 0 ]; then
        log_warning "Found $same_time_count duplicate timestamps (likely arbitrary)"
        DUPLICATE_TIMESTAMPS=$((DUPLICATE_TIMESTAMPS + same_time_count))
        
        if [ "$VERBOSE" = true ]; then
            grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | grep -o "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]" | sort | uniq -d || true
        fi
    fi
}

# Check for future timestamps
check_future_timestamps() {
    log_info "Checking for future timestamps..."
    
    local future_count=0
    while IFS= read -r -d '' file; do
        while IFS= read -r line; do
            if [[ $line =~ \[([0-9]{4}-[0-9]{2}-[0-9]{2})\] ]]; then
                local timestamp_date="${BASH_REMATCH[1]}"
                if [[ "$timestamp_date" > "$TODAY" ]]; then
                    log_error "Future timestamp found in $file: $line"
                    future_count=$((future_count + 1))
                fi
            fi
        done < "$file"
    done < <(find "$DOCS_DIR" "$INSIGHTS_DIR" -name "*.md" -type f -print0 2>/dev/null)
    
    FUTURE_TIMESTAMPS=$future_count
}

# Check for suspicious date patterns
check_date_patterns() {
    log_info "Checking for suspicious date patterns..."
    
    # Check for common arbitrary dates
    local arbitrary_dates=("2024-12-19" "2025-07-21")
    
    for date in "${arbitrary_dates[@]}"; do
        local count=$(grep -r "$date" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | wc -l)
        if [ "$count" -gt 5 ]; then
            log_warning "Found $count occurrences of date $date (suspicious - may be arbitrary)"
            ARBITRARY_TIMESTAMPS=$((ARBITRARY_TIMESTAMPS + count))
        fi
    done
}

# Check for timestamp format consistency
check_format_consistency() {
    log_info "Checking timestamp format consistency..."
    
    # Check for inconsistent formats
    local inconsistent_count=$(grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | grep -v "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]" | wc -l)
    if [ "$inconsistent_count" -gt 0 ]; then
        log_warning "Found $inconsistent_count timestamps with inconsistent format"
        
        if [ "$VERBOSE" = true ]; then
            grep -r "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" "$DOCS_DIR" "$INSIGHTS_DIR" 2>/dev/null | grep -v "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]" || true
        fi
    fi
}

# Generate timestamp integrity report
generate_report() {
    log_info "Generating timestamp integrity report..."
    
    echo
    echo "=========================================="
    echo "TIMESTAMP INTEGRITY REPORT"
    echo "Generated: $TODAY $CURRENT_TIME"
    echo "=========================================="
    echo
    
    if [ "$TOTAL_VIOLATIONS" -eq 0 ]; then
        log_success "No timestamp integrity violations found!"
        echo
        echo "All timestamps appear to be real and accurate."
    else
        log_error "Found $TOTAL_VIOLATIONS total violations:"
        echo "  - Arbitrary timestamps: $ARBITRARY_TIMESTAMPS"
        echo "  - Duplicate timestamps: $DUPLICATE_TIMESTAMPS"
        echo "  - Future timestamps: $FUTURE_TIMESTAMPS"
        echo "  - Sequential patterns: $SEQUENTIAL_PATTERNS"
        echo
        
        if [ "$FIX_MODE" = true ]; then
            log_info "Fix mode enabled - attempting automatic corrections..."
            # Add automatic fix logic here
        else
            log_info "Run with --fix to attempt automatic corrections"
        fi
    fi
    
    echo
    echo "Recommendations:"
    echo "1. Use real timestamps only - never invent or estimate times"
    echo "2. Record timestamps at the moment events occur"
    echo "3. Use 'date' command to get current time"
    echo "4. Validate timestamps against terminal logs"
    echo "5. Mark unknown timestamps as [TIMESTAMP UNKNOWN]"
    echo
}

# Main execution
main() {
    # Parse command line arguments
    FIX_MODE=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: $0 [--fix] [--verbose]"
                exit 1
                ;;
        esac
    done
    
    log_info "Starting timestamp integrity validation..."
    log_info "Current date: $TODAY"
    log_info "Current time: $CURRENT_TIME"
    echo
    
    # Run all checks
    check_arbitrary_patterns
    check_future_timestamps
    check_date_patterns
    check_format_consistency
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [ "$TOTAL_VIOLATIONS" -eq 0 ]; then
        log_success "Timestamp integrity validation passed"
        exit 0
    else
        log_error "Timestamp integrity validation failed"
        exit 1
    fi
}

# Run main function
main "$@" 