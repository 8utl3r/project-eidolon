# Thought Validator
#
# This module validates thoughts to ensure they meet linguistic requirements.
# Thoughts cannot be single words unless they are linguistically necessary.

import std/[strutils, tables, sequtils, options]
import ../types

const
  # Linguistically necessary single words that are allowed as thoughts
  NECESSARY_SINGLE_WORDS* = @[
    # Pronouns
    "i", "you", "he", "she", "it", "we", "they",
    "me", "him", "her", "us", "them",
    "my", "your", "his", "her", "its", "our", "their",
    "mine", "yours", "his", "hers", "ours", "theirs",
    
    # Articles
    "a", "an", "the",
    
    # Conjunctions
    "and", "or", "but", "nor", "yet", "so",
    "because", "although", "unless", "while", "whereas",
    
    # Prepositions
    "in", "on", "at", "to", "for", "of", "with", "by", "from", "up", "about",
    "into", "through", "during", "before", "after", "above", "below",
    "between", "among", "within", "without", "against", "toward", "towards",
    
    # Interjections
    "yes", "no", "okay", "ok", "wow", "oh", "ah", "oops", "ouch",
    
    # Common verbs (only in imperative or infinitive forms)
    "be", "do", "go", "come", "see", "look", "listen", "stop", "wait",
    
    # Numbers and quantities
    "one", "two", "three", "first", "second", "third", "all", "some", "none",
    "many", "few", "several", "each", "every", "any", "both", "either", "neither",
    
    # Directional words
    "here", "there", "where", "everywhere", "nowhere", "somewhere",
    "up", "down", "left", "right", "forward", "backward",
    
    # Temporal words
    "now", "then", "when", "always", "never", "sometimes", "often", "rarely",
    "today", "yesterday", "tomorrow", "tonight", "morning", "afternoon", "evening",
    
    # Modal verbs
    "can", "could", "will", "would", "shall", "should", "may", "might", "must"
  ]

type
  ThoughtValidationResult* = object
    is_valid*: bool
    reason*: string
    suggestions*: seq[string]

  ThoughtValidator* = object
    necessary_words*: Table[string, bool]
    word_count_threshold*: int  # Minimum words for non-necessary thoughts

# Constructor
proc newThoughtValidator*(): ThoughtValidator =
  var validator = ThoughtValidator(
    necessary_words: initTable[string, bool](),
    word_count_threshold: 2  # At least 2 words for non-necessary thoughts
  )
  
  # Initialize necessary words table
  for word in NECESSARY_SINGLE_WORDS:
    validator.necessary_words[word.toLowerAscii()] = true
  
  return validator

# Validation Functions
proc validateThought*(validator: ThoughtValidator, thought_text: string): ThoughtValidationResult =
  ## Validate a thought to ensure it meets linguistic requirements
  
  let words = thought_text.strip().splitWhitespace()
  
  # Empty thought is invalid
  if words.len == 0:
    return ThoughtValidationResult(
      is_valid: false,
      reason: "Thought cannot be empty",
      suggestions: @["Add meaningful content to the thought"]
    )
  
  # Single word validation
  if words.len == 1:
    let single_word = words[0].toLowerAscii()
    
    # Check if it's a linguistically necessary single word
    if validator.necessary_words.hasKey(single_word):
      return ThoughtValidationResult(
        is_valid: true,
        reason: "Single word is linguistically necessary",
        suggestions: @[]
      )
    else:
      return ThoughtValidationResult(
        is_valid: false,
        reason: "Single word '" & words[0] & "' is not linguistically necessary",
        suggestions: @[
          "Expand to a multi-word concept (e.g., '" & words[0] & " is important')",
          "Combine with related concepts (e.g., '" & words[0] & " and its applications')",
          "Add context or definition (e.g., '" & words[0] & " refers to...')"
        ]
      )
  
  # Multi-word thoughts are generally valid
  if words.len >= validator.word_count_threshold:
    return ThoughtValidationResult(
      is_valid: true,
      reason: "Multi-word thought meets requirements",
      suggestions: @[]
    )
  
  # Edge case: exactly 2 words but might need validation
  if words.len == 2:
    # Check if both words are necessary single words
    let word1 = words[0].toLowerAscii()
    let word2 = words[1].toLowerAscii()
    
    if validator.necessary_words.hasKey(word1) and validator.necessary_words.hasKey(word2):
      # Both are necessary words - might be too basic
      return ThoughtValidationResult(
        is_valid: false,
        reason: "Thought contains only necessary words without meaningful content",
        suggestions: @[
          "Add substantive content (e.g., '" & thought_text & " in context of...')",
          "Expand to include concepts or relationships",
          "Provide definition or explanation"
        ]
      )
  
  return ThoughtValidationResult(
    is_valid: true,
    reason: "Thought meets requirements",
    suggestions: @[]
  )

proc validateThoughtConnections*(validator: ThoughtValidator, connections: seq[string]): ThoughtValidationResult =
  ## Validate the connections that form a thought
  
  if connections.len == 0:
    return ThoughtValidationResult(
      is_valid: false,
      reason: "Thought must have at least one connection",
      suggestions: @["Add at least one entity connection to form a thought"]
    )
  
  if connections.len == 1:
    # Single connection might be valid for necessary words, but generally should have multiple
    return ThoughtValidationResult(
      is_valid: true,
      reason: "Single connection thought (may be necessary word)",
      suggestions: @["Consider adding more connections for richer thought structure"]
    )
  
  # Multiple connections are good
  return ThoughtValidationResult(
    is_valid: true,
    reason: "Multiple connections form meaningful thought",
    suggestions: @[]
  )

# Batch Validation
proc validateThoughts*(validator: ThoughtValidator, thoughts: seq[Thought]): Table[string, ThoughtValidationResult] =
  ## Validate multiple thoughts and return results
  
  var results = initTable[string, ThoughtValidationResult]()
  
  for thought in thoughts:
    let validation = validator.validateThought(thought.connections.join(" "))
    results[thought.id] = validation
  
  return results

# Cleanup Functions
proc filterValidThoughts*(validator: ThoughtValidator, thoughts: seq[Thought]): seq[Thought] =
  ## Filter out invalid thoughts, keeping only valid ones
  
  return thoughts.filterIt(validator.validateThought(it.connections.join(" ")).is_valid)

proc getInvalidThoughts*(validator: ThoughtValidator, thoughts: seq[Thought]): seq[Thought] =
  ## Get only invalid thoughts for review
  
  return thoughts.filterIt(not validator.validateThought(it.connections.join(" ")).is_valid)

# Suggestion Functions
proc suggestThoughtImprovements*(validator: ThoughtValidator, thought_text: string): seq[string] =
  ## Get suggestions for improving a thought
  
  let validation = validator.validateThought(thought_text)
  return validation.suggestions

proc suggestThoughtExpansion*(validator: ThoughtValidator, single_word: string): seq[string] =
  ## Suggest ways to expand a single word into a valid thought
  
  let word = single_word.toLowerAscii()
  
  if validator.necessary_words.hasKey(word):
    return @["Single word '" & single_word & "' is already valid as a necessary word"]
  
  # Generate expansion suggestions based on word type
  var suggestions: seq[string] = @[]
  
  # Common patterns for expansion
  suggestions.add(single_word & " is a concept that")
  suggestions.add(single_word & " refers to")
  suggestions.add(single_word & " can be defined as")
  suggestions.add(single_word & " relates to")
  suggestions.add(single_word & " involves")
  suggestions.add(single_word & " includes")
  suggestions.add(single_word & " represents")
  suggestions.add(single_word & " describes")
  suggestions.add(single_word & " means")
  suggestions.add(single_word & " is used for")
  
  return suggestions

# Utility Functions
proc isNecessaryWord*(validator: ThoughtValidator, word: string): bool =
  ## Check if a word is linguistically necessary
  
  return validator.necessary_words.hasKey(word.toLowerAscii())

proc getNecessaryWords*(): seq[string] =
  ## Get list of all linguistically necessary words
  
  return NECESSARY_SINGLE_WORDS

proc countValidThoughts*(validator: ThoughtValidator, thoughts: seq[Thought]): int =
  ## Count how many thoughts are valid
  
  return thoughts.countIt(validator.validateThought(it.connections.join(" ")).is_valid)

proc countInvalidThoughts*(validator: ThoughtValidator, thoughts: seq[Thought]): int =
  ## Count how many thoughts are invalid
  
  return thoughts.countIt(not validator.validateThought(it.connections.join(" ")).is_valid) 