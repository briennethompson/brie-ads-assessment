# ============================================================
# Program:  question_4.py
# Purpose:  GenAI Clinical Data Assistant
#           Translates natural language questions into
#           structured Pandas queries using mock LLM
# Input:    adae.csv (pharmaversesdtm::ae)
# ============================================================

import pandas as pd
import json
import os

# ============================================================
# 1. Load Data
# ============================================================

# Set working directory
os.chdir("/cloud/project/brie-ads-assessment")

# Load AE dataset
ae = pd.read_csv("question_4/adae.csv")

# Confirm data loaded correctly
print("Data loaded successfully")
print(f"Shape: {ae.shape}")
print(f"Columns: {ae.columns.tolist()}")

# ============================================================
# 2. Schema Definition
# ============================================================

SCHEMA = """
You are a clinical data assistant. The dataset contains adverse event (AE)
data from a clinical trial. Here are the relevant columns:

- USUBJID: Unique subject identifier
- AETERM: Reported adverse event term (e.g., "Headache", "Nausea")
- AESOC: System organ class - body system category
         (e.g., "CARDIAC DISORDERS", "SKIN AND SUBCUTANEOUS TISSUE DISORDERS")
- AESEV: Severity or intensity of the AE
         (values: "MILD", "MODERATE", "SEVERE")
- AESTDTC: Start date of the AE
- AEENDTC: End date of the AE
- AESER: Serious AE flag (Y/N)

Your job is to parse a user's natural language question and return ONLY a
JSON object with exactly two fields:
- target_column: The column name to filter on
- filter_value: The value to search for (in UPPERCASE)

Example response:
{"target_column": "AESEV", "filter_value": "MODERATE"}

Return ONLY the JSON object. No explanation, no markdown, no extra text.
"""

# ============================================================
# 3. ClinicalTrialDataAgent Class
# ============================================================

class ClinicalTrialDataAgent:
    """
    A GenAI agent that translates natural language questions
    into structured Pandas queries using an LLM.
    """

    def __init__(self, dataframe, use_mock=True):
        """
        Initialize the agent with the AE dataframe.

        Args:
            dataframe: Pandas DataFrame containing AE data
            use_mock:  If True uses mock LLM responses instead
                       of calling OpenAI API
        """
        self.df       = dataframe
        self.use_mock = use_mock

    def _call_llm(self, question):
        """
        Call the LLM to parse the user question into structured JSON.

        Args:
            question: Natural language question from user

        Returns:
            dict with target_column and filter_value
        """
        if self.use_mock:
            return self._mock_llm_response(question)
        else:
            return self._openai_llm_response(question)

    def _mock_llm_response(self, question):
        """
        Mock LLM response for testing without an API key.
        Simulates the Prompt -> Parse -> Execute flow.

        Args:
            question: Natural language question from user

        Returns:
            dict with target_column and filter_value
        """
        question_lower = question.lower()

        # Map severity/intensity questions to AESEV
        if any(word in question_lower for word in
               ["severity", "intense", "intensity", "severe",
                "moderate", "mild"]):
            if "moderate" in question_lower:
                return {"target_column": "AESEV",
                        "filter_value":  "MODERATE"}
            elif "severe" in question_lower:
                return {"target_column": "AESEV",
                        "filter_value":  "SEVERE"}
            elif "mild" in question_lower:
                return {"target_column": "AESEV",
                        "filter_value":  "MILD"}

        # Map body system questions to AESOC
        if any(word in question_lower for word in
               ["system", "organ", "body", "cardiac", "skin",
                "nervous", "gastro"]):
            if "cardiac" in question_lower:
                return {"target_column": "AESOC",
                        "filter_value":  "CARDIAC DISORDERS"}
            elif "skin" in question_lower:
                return {"target_column": "AESOC",
                        "filter_value":  "SKIN AND SUBCUTANEOUS TISSUE DISORDERS"}
            elif "nervous" in question_lower:
                return {"target_column": "AESOC",
                        "filter_value":  "NERVOUS SYSTEM DISORDERS"}

        # Map specific condition questions to AETERM
        for term in self.df["AETERM"].dropna().unique():
            if term.lower() in question_lower:
                return {"target_column": "AETERM",
                        "filter_value":  term.upper()}

        # Default fallback
        return {"target_column": None, "filter_value": None}

    def _openai_llm_response(self, question):
        """
        Call OpenAI API to parse the user question.
        Requires OPENAI_API_KEY environment variable to be set.

        Args:
            question: Natural language question from user

        Returns:
            dict with target_column and filter_value
        """
        from openai import OpenAI

        client = OpenAI()  # reads OPENAI_API_KEY from environment

        response = client.chat.completions.create(
            model       = "gpt-4o-mini",
            messages    = [
                {"role": "system", "content": SCHEMA},
                {"role": "user",   "content": question}
            ],
            temperature = 0  # deterministic output
        )

        # Parse JSON response from LLM
        raw = response.choices[0].message.content.strip()
        return json.loads(raw)

    def execute_query(self, llm_output):
        """
        Apply the LLM's structured output as a Pandas filter.

        Args:
            llm_output: dict with target_column and filter_value

        Returns:
            dict with subject count and list of matching USUBJIDs
        """
        target_column = llm_output.get("target_column")
        filter_value  = llm_output.get("filter_value")

        # Handle unmapped questions
        if not target_column or not filter_value:
            return {
                "error":         "Could not map question to a dataset column",
                "subject_count": 0,
                "subject_ids":   []
            }

        # Validate column exists in dataframe
        if target_column not in self.df.columns:
            return {
                "error":         f"Column '{target_column}' not found in dataset",
                "subject_count": 0,
                "subject_ids":   []
            }

        # Apply filter - case insensitive match
        filtered = self.df[
            self.df[target_column].str.upper() == filter_value.upper()
        ]

        # Get unique subjects
        unique_subjects = filtered["USUBJID"].dropna().unique().tolist()

        return {
            "target_column": target_column,
            "filter_value":  filter_value,
            "subject_count": len(unique_subjects),
            "subject_ids":   sorted(unique_subjects)
        }

    def ask(self, question):
        """
        Main entry point - takes a natural language question,
        calls LLM, executes query, and returns results.

        Args:
            question: Natural language question from user

        Returns:
            dict with query results
        """
        print(f"\nQuestion: {question}")
        print("-" * 60)

        # Step 1: Call LLM to parse question
        llm_output = self._call_llm(question)
        print(f"LLM Output:    {llm_output}")

        # Step 2: Execute the query
        result = self.execute_query(llm_output)
        print(f"Subject Count: {result['subject_count']}")
        print(f"Subject IDs:   {result['subject_ids']}")

        return result


# ============================================================
# 4. Test Script - 3 Example Queries
# ============================================================

if __name__ == "__main__":

    print("=" * 60)
    print("Clinical Trial Data Agent - Test Queries")
    print("=" * 60)

    # Initialize agent with mock LLM
    # Set use_mock=False and set OPENAI_API_KEY to use real LLM
    agent = ClinicalTrialDataAgent(ae, use_mock=True)

    # Query 1 - Severity
    result1 = agent.ask(
        "Give me the subjects who had adverse events of moderate severity"
    )

    # Query 2 - Body system
    result2 = agent.ask(
        "Which subjects had adverse events related to the skin?"
    )

    # Query 3 - Specific AE term
    result3 = agent.ask(
        "Show me subjects who experienced headache"
    )

    print("\n" + "=" * 60)
    print("All queries completed successfully")
    print("=" * 60)
